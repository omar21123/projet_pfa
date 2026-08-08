# Stratégie d'Indexation & Contraintes — Base de Données Marketplace

> Documentation technique du schéma MySQL 8.0 — à conserver dans `/docs` ou à la racine du repo backend.

## Sommaire

- [Conventions de nommage](#conventions-de-nommage)
- [Principes généraux appliqués](#principes-généraux-appliqués)
- [Différences MySQL vs SQL Server](#différences-mysql-vs-sql-server)
- [Détail par module](#détail-par-module)
- [Recommandations de suivi](#recommandations-de-suivi)

---

## Conventions de nommage

| Préfixe | Signification | Exemple |
|---|---|---|
| `PK_` | Clé primaire (implicite via `PRIMARY KEY`) | `Users.UserID` |
| `FK_<Table>_<Cible>` | Clé étrangère | `FK_Products_Vendor` |
| `UX_<Table>_<Colonne(s)>` | Index unique | `UX_Users_Email` |
| `IX_<Table>_<Colonne(s)>` | Index standard (non unique) | `IX_Products_VendorID` |
| `IXF_<Table>_<Colonne(s)>` | Index "filtré" logique (soft-delete / statut) | `IXF_Products_Storefront` |
| `IXC_<Table>_<Colonne(s)>` | Index de couverture (covering index) | `IXC_Users_Email_Login` |
| `FTX_<Table>_<Colonne>` | Index full-text (recherche libre) | `FTX_ProductSearchIndex_SearchText` |

---

## Principes généraux appliqués

1. **Toute colonne FK est indexée.** Contrairement à SQL Server (et contrairement à ce qu'on croit souvent), MySQL n'indexe automatiquement que les clés primaires — chaque jointure du schéma repose sur une FK, donc chacune a son index dédié.
2. **Les booléens ne sont jamais indexés seuls** (`IsActive`, `IsDeleted`, `IsBlocked`...). Un index sur une colonne à 2 valeurs possibles est rarement utilisé par l'optimiseur. Ils sont systématiquement combinés avec une colonne de tri/filtre réelle (ex. `IXF_Products_Storefront (IsActive, IsBlocked, Status, CreatedAt)`).
3. **Les clés métier** (`PublicID`, `Slug`, `Code`, `Barcode`, `OrderNumber`, `TransactionID`...) ont un index **unique**, à la fois pour la performance des lookups et pour garantir l'intégrité au niveau base de données (pas seulement côté application).
4. **Les requêtes fréquentes** (écran de commandes, dashboard vendeur, file de modération produits, notifications non lues) ont des index composites qui reflètent exactement la forme `WHERE ... ORDER BY ...` attendue.
5. **Ordre des colonnes** dans les index composites : la colonne la plus filtrée en premier, la colonne de tri en dernier — cohérent avec le pattern `SP_[Action][Entité]` utilisé côté procédures stockées.

---

## Différences MySQL vs SQL Server

Ce point est important si tu compares avec le script SQL Server d'origine :

| SQL Server | MySQL | Impact |
|---|---|---|
| Index filtré (`CREATE INDEX ... WHERE IsDeleted = 0`) | ❌ Non supporté | Tous les index MySQL indexent l'intégralité des lignes, y compris les lignes supprimées/inactives. Acceptable au volume actuel du projet. |
| `INCLUDE (col1, col2)` pour un covering index | ❌ Non supporté | Les colonnes supplémentaires sont intégrées directement dans l'index composite (ex. `IXC_Users_Email_Login`). |
| `NVARCHAR` | `VARCHAR` + charset `utf8mb4` | `utf8mb4` gère déjà l'arabe et le français sans type séparé. |
| `BIT` | `TINYINT(1)` | Équivalent booléen. |
| `UNIQUEIDENTIFIER` (UUID natif) | `CHAR(36) DEFAULT (UUID())` | Pas de type UUID natif en MySQL. |
| Recherche full-text | `CONTAINS` / `FREETEXT` | `FULLTEXT KEY` (syntaxe MySQL native). |

---

## Détail par module

### 1. Identité & Accès (`Users`, `UserExternalLogins`, `Roles`, `UserRoles`, `VendorProfiles`, `AdminProfiles`, `CustomerProfiles`)

- `UX_Users_PublicID`, `UX_Users_Email`, `UX_Users_PhoneNumber` — unicité garantie en base.
- `IXC_Users_Email_Login (Email, PasswordHash, IsActive, EmailVerified, HasPassword)` — index de couverture pour la procédure de login, évite un aller-retour supplémentaire vers la table.
- `IXF_Users_Active_CreatedAt` — liste des utilisateurs actifs, back-office.
- `UX_UserExternalLogins_Provider (Provider, ProviderUserID)` — empêche la double liaison d'un même compte OAuth.
- `UX_VendorProfiles_UserID`, `UX_AdminProfiles_UserID`, `UX_CustomerProfiles_UserID` — relation 1:1 stricte avec `Users`.
- FK en cascade (`ON DELETE CASCADE`) sur tous les profils : la suppression d'un `User` supprime son profil associé.

### 2. Adresses (`Addresses`)

- `IX_Addresses_UserID` — FK obligatoire.
- `IXF_Addresses_DefaultShipping`, `IXF_Addresses_DefaultBilling` — récupération rapide de l'adresse par défaut à l'affichage du panier/checkout.

### 3. Finance Vendeur (`BankAccounts`, `WithdrawHistory`, `PaymentInformations`)

- `UX_BankAccounts_VendorProfileID` — un seul compte bancaire par vendeur.
- `IXF_WithdrawHistory_Status` — file d'attente des retraits en attente (écran admin).
- `IXF_PaymentInformations_Default` — moyen de paiement par défaut de l'utilisateur.

### 4. Catalogue (`Categories`, `CategoryClosure`, `Brands`, `Models`, `ProductsConfigAttribute`, `ConfigAttributeOptions`)

- `UX_Categories_Slug`, `UX_Brands_Slug` — URLs SEO uniques.
- `CategoryClosure` (table de fermeture transitive) : deux index couvrant les deux sens de lecture — `IX_CategoryClosure_DescendantID` (« tous les ancêtres de X ») et `IX_CategoryClosure_AncestorID` (« tous les descendants de X, à N niveaux »).
- `UX_Models_Brand_Code` — un code de modèle unique par marque (pas globalement).

### 5. Produits (`Products`, `ProductResources`, `ProductAllowedPayements`, `ProductDetails`, `ProductCategories`, `ProductTags`)

- **Table la plus sollicitée du schéma.**
- `UX_Products_Barcode` — unicité du code-barres (uniquement sur les produits non supprimés côté logique applicative).
- `IXF_Products_Storefront (IsActive, IsBlocked, Status, CreatedAt)` — l'index le plus critique : alimente toutes les pages de listing/recherche côté client.
- `IX_Products_Vendor_Status` — dashboard vendeur, « mes produits par statut ».
- `IXF_Products_PendingValidation` — file de modération admin (produits en attente de validation, du plus ancien au plus récent).
- `IXC_ProductResources_Product_Role` — récupération de l'image principale d'un produit sans lookup supplémentaire.
- `IX_ProductDetails_Attribute_Option` — filtrage à facettes (« produits où attribut X = valeur Y »).

### 6. Recherche & Classement (`ProductSearchIndex`, `SearchDictionary`, `UserSearchHistory`, `SearchSynonyms`, `SearchTermProductStats`, `ProductRankingFactors`, `RegionalProductStats`, `IPGeoLocations`)

- `FTX_ProductSearchIndex_SearchText` — recherche full-text native MySQL (remplace le `CONTAINS` SQL Server).
- `UX_SearchDictionary_NormalizedText` — un seul terme normalisé par entrée du dictionnaire.
- `IXF_SearchDictionary_TopTerms` — alimente l'autocomplétion (termes actifs triés par score).
- `UX_IPGeoLocations_IPAddress` — cache de géolocalisation par IP, une entrée par IP.
- `IXF_ProductRankingFactors_Score` / `IXF_ProductRankingFactors_Featured` — cœur du moteur de classement produit (en stock, trié par score final).

### 7. Panier & Liste de souhaits (`Carts`, `CartItems`, `WishLists`, `WishListItems`)

- `UX_Carts_UserID` — un panier actif par utilisateur.
- `UX_CartItems_Cart_Product_Variant` — empêche les doublons de ligne panier (même produit + variante ajoutés deux fois).
- `UX_WishListItems_List_Product` — idem pour la liste de souhaits.

### 8. Commandes & Paiements (`Orders`, `OrderItems`, `OrderStatus`, `Payments`, `PaymentMethods`)

- `UX_Orders_OrderNumber` — numéro de commande unique, visible client.
- `UX_Payments_TransactionID` — empêche le traitement en double d'une même transaction.
- **Cas particulier : référence circulaire** entre `Orders.PaymentID` et `Payments.OrderID`. La contrainte `FK_Orders_Payment` est ajoutée via `ALTER TABLE` après la création de `Payments`, car MySQL ne permet pas de référencer une table qui n'existe pas encore.
- `IX_OrderItems_VendorProfileID` — dashboard des ventes par vendeur.

### 9. Notifications (`Notifications`, `NotificationTypes`, `UserDevices`, `UserNotificationPreferences`, `NotificationDeliveryLog`)

- `IXF_Notifications_User_Unread (UserID, IsRead, CreatedAt)` — requête la plus fréquente du module : notifications non lues, plus récentes en premier.
- `UX_UserDevices_FCMToken` — un token FCM ne peut être lié qu'à un seul device actif.
- `UX_UserNotificationPreferences_User_Type` — une seule préférence par utilisateur et par type de notification.

### 10. Moteur de recommandation (`FAIT_EVENEMENT_CLIENT`, `FAIT_SCORE_CLIENT_PRODUIT`, `DIM_TYPE_EVENEMENT`)

- Tables de faits — volumétrie qui grossit vite. Les index sont pensés pour les jobs d'agrégation (par utilisateur, par produit), pas pour du point-lookup isolé.
- ⚠️ **À surveiller** : envisager un partitionnement par `date_evenement` une fois le volume mensuel significatif — l'indexation seule ne suffira pas à maintenir les performances d'écriture sur une table de faits qui grossit en continu.

---

## Recommandations de suivi

- **Ne pas indexer "au cas où".** Une fois en environnement de test/production, exécuter :
  ```sql
  SELECT * FROM performance_schema.table_io_waits_summary_by_index_usage
  WHERE INDEX_NAME IS NOT NULL
  ORDER BY COUNT_STAR DESC;
  ```
  pour identifier les index réellement utilisés (lectures) — supprimer ceux qui ne servent jamais, chaque index inutilisé ralentit les `INSERT`/`UPDATE`/`DELETE` pour rien.
- **Recherche texte libre** (description produit, nom de boutique) : privilégier `FULLTEXT` plutôt que `LIKE '%terme%'`, qui ignore systématiquement les index classiques.
- **Index géospatiaux** (Adresses, IPGeoLocations) : non mis en place pour l'instant. À ajouter (type `POINT` + `SPATIAL INDEX`) uniquement si une fonctionnalité "produits/vendeurs à proximité" est développée.
- **Contraintes `ON DELETE`** : la majorité des relations parent → enfant sont en `CASCADE`. Les relations métier critiques (ex. `Products → OrderItems`) sont en `RESTRICT` pour éviter la perte d'historique de vente. À revalider par rapport à ta stratégie de soft-delete (`IsDeleted`/`DeletedAt`), qui rend en théorie la plupart des suppressions physiques inutiles.
