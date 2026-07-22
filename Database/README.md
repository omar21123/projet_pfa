# Documentation du schéma — Marketplace Platform (MySQL 8.0)

> Ce document décrit, section par section, le schéma SQL d'initialisation de la base `marketplace_db`.
> Chaque table est présentée avec son rôle métier, ses colonnes clés et ses relations.

## Sommaire

- [1. Tables de référence (Lookup / Reference Tables)](#1-tables-de-référence-lookup--reference-tables)
- [2. Identité & Accès](#2-identité--accès)
- [3. Adresses](#3-adresses)
- [4. Finance Vendeur](#4-finance-vendeur)
- [5. Catalogue : Catégories, Attributs, Marques](#5-catalogue--catégories-attributs-marques)
- [6. Produits](#6-produits)
- [7. Recherche & Classement](#7-recherche--classement)
- [8. Panier & Liste de souhaits](#8-panier--liste-de-souhaits)
- [9. Commandes & Paiements](#9-commandes--paiements)
- [10. Notifications](#10-notifications)
- [11. Moteur de recommandation (tables de faits)](#11-moteur-de-recommandation-tables-de-faits)

---

## 1. Tables de référence (Lookup / Reference Tables)

Ces tables ne dépendent d'aucune autre table (pas de clé étrangère entrante). Elles servent de **listes de valeurs contrôlées** (référentiels) utilisées par le reste du schéma pour éviter la duplication de données statiques et garantir la cohérence (pays, rôles, moyens de paiement, statuts, etc.).

### 1.1. `Countries` — Pays

Référentiel des pays utilisé notamment pour rattacher une marque (`Brands`) à son pays d'origine.

| Colonne     | Type          | Description                                  |
|-------------|---------------|-----------------------------------------------|
| CountryID   | INT (PK, AI)  | Identifiant interne du pays                   |
| Code        | CHAR(2)       | Code ISO du pays (unique)                     |
| Name        | VARCHAR(100)  | Nom du pays                                   |

**Contraintes** : `Code` est unique (`UX_Countries_Code`).

---

### 1.2. `Roles` — Rôles applicatifs

Définit les rôles pouvant être attribués aux utilisateurs (ex : Admin, Vendeur, Client) via la table de liaison `UserRoles`.

| Colonne     | Type          | Description                                              |
|-------------|---------------|-----------------------------------------------------------|
| RoleID      | INT (PK, AI)  | Identifiant du rôle                                        |
| Name        | VARCHAR(100)  | Nom lisible du rôle                                        |
| Code        | VARCHAR(50)   | Code technique unique (ex : `ADMIN`, `VENDOR`, `CUSTOMER`) |
| Description | VARCHAR(255)  | Description libre                                          |
| IsSystem    | TINYINT(1)    | Indique un rôle système (non modifiable/supprimable)       |
| CreatedAt   | DATETIME      | Date de création                                            |

**Contraintes** : `Code` unique (`UX_Roles_Code`).
**Relations** : référencée par `UserRoles.RoleID`.

---

### 1.3. `PaymentMethods` — Moyens de paiement

Référentiel des moyens de paiement disponibles sur la plateforme (carte, virement, PayPal, crypto, etc.), utilisé aussi bien côté commande que côté retrait vendeur.

| Colonne         | Type           | Description                                              |
|-----------------|----------------|-----------------------------------------------------------|
| PaymentMethodID | INT (PK, AI)   | Identifiant du moyen de paiement                           |
| Name            | VARCHAR(100)   | Nom affiché                                                |
| Code            | VARCHAR(50)    | Code technique unique                                       |
| IconURL         | VARCHAR(500)   | URL de l'icône                                              |
| WithdrawTax     | DECIMAL(12,2)  | Taxe/frais appliqué lors d'un retrait via ce moyen          |
| IsOnline        | TINYINT(1)     | Paiement en ligne (1) ou hors-ligne (0)                     |
| IsActive        | TINYINT(1)     | Moyen de paiement actif / désactivé                         |
| DisplayOrder    | INT            | Ordre d'affichage dans l'UI                                 |

**Contraintes** : `Code` unique (`UX_PaymentMethods_Code`).
**Relations** : référencée par `PaymentInformations`, `WithdrawHistory`, `Payments`, `ProductAllowedPayements`.

---

### 1.4. `OrderStatus` — Statuts de commande

Référentiel du cycle de vie d'une commande (ex : en attente, confirmée, expédiée, livrée, annulée — voir le seed commenté en fin de script).

| Colonne       | Type          | Description                          |
|---------------|---------------|----------------------------------------|
| OrderStatusID | INT (PK, AI)  | Identifiant du statut                  |
| Name          | VARCHAR(100)  | Libellé du statut                      |
| Code          | VARCHAR(50)   | Code technique unique                   |
| DisplayOrder  | INT           | Ordre d'affichage / progression logique |

**Contraintes** : `Code` unique (`UX_OrderStatus_Code`).
**Relations** : référencée par `Orders.OrderStatusID`.

---

### 1.5. `NotificationTypes` — Types de notification

Catalogue des types de notifications push/in-app possibles, avec leurs modèles de titre/corps (templating), permettant de générer des notifications homogènes.

| Colonne             | Type          | Description                                                        |
|---------------------|---------------|----------------------------------------------------------------------|
| NotificationTypeID  | INT (PK, AI)  | Identifiant du type                                                   |
| Code                | VARCHAR(50)   | Code technique unique                                                 |
| Category            | TINYINT       | Catégorie fonctionnelle (ex : commande, marketing, sécurité…)         |
| TitleTemplate       | VARCHAR(255)  | Modèle du titre (avec variables à interpoler)                        |
| BodyTemplate        | VARCHAR(500)  | Modèle du corps du message                                            |
| DefaultPushEnabled  | TINYINT(1)    | Activation par défaut du push pour ce type                            |
| IsUserConfigurable  | TINYINT(1)    | L'utilisateur peut-il désactiver ce type dans ses préférences ?       |
| IsActive            | TINYINT(1)    | Type actif dans le système                                            |
| CreatedAt           | DATETIME      | Date de création                                                       |

**Contraintes** : `Code` unique (`UX_NotificationTypes_Code`).
**Relations** : référencée par `Notifications.NotificationTypeID`, `UserNotificationPreferences.NotificationTypeID`.

---

### 1.6. `Units` — Unités de mesure

Référentiel des unités (kg, L, pièce, etc.) utilisables dans les attributs de configuration produit (`ProductsConfigAttribute`).

| Colonne      | Type          | Description                       |
|--------------|---------------|-------------------------------------|
| UnitID       | INT (PK, AI)  | Identifiant de l'unité               |
| Name         | VARCHAR(100)  | Nom complet de l'unité                |
| Symbol       | VARCHAR(20)   | Symbole (kg, L, pcs…)                 |
| DisplayOrder | INT           | Ordre d'affichage                     |
| IsActive     | TINYINT(1)    | Unité active                          |

**Relations** : référencée par `ProductsConfigAttribute.UnitID`.

---

### 1.7. `ResourcesTypes` — Types de ressources média

Référentiel des types de fichiers/ressources associés à un produit (ex : image, vidéo, document).

| Colonne | Type          | Description                     |
|---------|---------------|------------------------------------|
| ID      | INT (PK, AI)  | Identifiant du type de ressource    |
| Name    | VARCHAR(50)   | Nom du type (unique)                |

**Contraintes** : `Name` unique (`UX_ResourcesTypes_Name`).
**Relations** : référencée par `ProductResources.ResourcesTypeID`.

---

### 1.8. `ResourcesRoles` — Rôles des ressources média

Référentiel du **rôle fonctionnel** d'une ressource dans une fiche produit (ex : image principale, galerie, miniature, document technique).

| Colonne | Type          | Description                    |
|---------|---------------|-----------------------------------|
| RoleID  | INT (PK, AI)  | Identifiant du rôle de ressource   |
| Label   | VARCHAR(50)   | Libellé du rôle (unique)           |

**Contraintes** : `Label` unique (`UX_ResourcesRoles_Label`).
**Relations** : référencée par `ProductResources.ResourceRoleID`.

---

### 1.9. `Tags` — Étiquettes

Référentiel de tags libres pouvant être associés à un ou plusieurs produits (ex : "Promo", "Nouveau", "Éco-responsable"), utilisé pour le filtrage/mise en avant.

| Colonne     | Type          | Description                     |
|-------------|---------------|------------------------------------|
| TagID       | INT (PK, AI)  | Identifiant du tag                  |
| Name        | VARCHAR(100)  | Nom du tag (unique)                 |
| Color       | VARCHAR(20)   | Couleur associée (affichage UI)     |
| Description | VARCHAR(255)  | Description libre                    |
| IsActive    | TINYINT(1)    | Tag actif                            |
| CreatedAt   | DATETIME      | Date de création                     |

**Contraintes** : `Name` unique (`UX_Tags_Name`).
**Relations** : référencée par `ProductTags.TagID`.

---

### 1.10. `DIM_TYPE_EVENEMENT` — Dimension : types d'événements

Table de dimension (au sens "data warehouse") listant les types d'événements comportementaux trackés pour le moteur de recommandation (ex : vue produit, ajout panier, achat), chacun associé à un nombre de points contribuant au score client/produit.

| Colonne             | Type          | Description                                         |
|---------------------|---------------|--------------------------------------------------------|
| id_type_evenement   | INT (PK, AI)  | Identifiant du type d'événement                          |
| code                | VARCHAR(50)   | Code technique unique de l'événement                     |
| nom                 | VARCHAR(100)  | Nom lisible de l'événement                                |
| points              | INT           | Poids/score attribué à cet événement                      |
| est_actif           | TINYINT(1)    | Type d'événement actif                                    |

**Contraintes** : `code` unique (`UX_DIM_TYPE_EVENEMENT_code`).
**Relations** : référencée par `FAIT_EVENEMENT_CLIENT.id_type_evenement`.

---

### Synthèse des relations de cette section

Ces 10 tables sont des **feuilles du graphe de dépendances** (aucune FK entrante) mais sont **fortement référencées** ailleurs dans le schéma :

| Table de référence     | Référencée par (table.colonne)                                                                 |
|-------------------------|--------------------------------------------------------------------------------------------------|
| `Countries`              | `Brands.CountryID`                                                                               |
| `Roles`                  | `UserRoles.RoleID`                                                                                |
| `PaymentMethods`         | `PaymentInformations`, `WithdrawHistory`, `Payments`, `ProductAllowedPayements`                  |
| `OrderStatus`            | `Orders.OrderStatusID`                                                                            |
| `NotificationTypes`      | `Notifications`, `UserNotificationPreferences`                                                    |
| `Units`                  | `ProductsConfigAttribute.UnitID`                                                                  |
| `ResourcesTypes`         | `ProductResources.ResourcesTypeID`                                                                |
| `ResourcesRoles`         | `ProductResources.ResourceRoleID`                                                                 |
| `Tags`                   | `ProductTags.TagID`                                                                               |
| `DIM_TYPE_EVENEMENT`     | `FAIT_EVENEMENT_CLIENT.id_type_evenement`                                                         |

> 💡 **Remarque de convention** : la plupart des tables de ce script suivent une convention **PascalCase / anglais** (ex : `Countries`, `Roles`), sauf les deux tables du moteur de recommandation (`DIM_TYPE_EVENEMENT`, `FAIT_EVENEMENT_CLIENT`, `FAIT_SCORE_CLIENT_PRODUIT`) qui suivent une convention **snake_case / français**, typique d'un modèle en étoile (schéma décisionnel). Cela suggère que cette partie a été conçue séparément (module analytique/BI) et mériterait d'être harmonisée si le style de nommage doit rester cohérent sur l'ensemble du projet.

---

---

## 2. Identité & Accès

Cette section gère les comptes utilisateurs, l'authentification (locale et via fournisseurs externes), les rôles, et les profils spécialisés selon le type d'acteur (vendeur, admin, client).

### 2.1. `Users` — Utilisateurs

Table centrale de l'application : un compte par personne physique, quel que soit son rôle (client, vendeur, admin — le rôle réel est déterminé via `UserRoles`).

| Colonne       | Type          | Description                                              |
|---------------|---------------|-------------------------------------------------------------|
| UserID        | INT (PK, AI)  | Identifiant interne                                           |
| PublicID      | CHAR(36)      | UUID public (généré par défaut), utilisable en URL/API        |
| FirstName     | VARCHAR(100)  | Prénom                                                          |
| LastName      | VARCHAR(100)  | Nom                                                             |
| DisplayName   | VARCHAR(150)  | Nom d'affichage                                                 |
| BirthDate     | DATE          | Date de naissance                                               |
| Gender        | TINYINT       | Genre (codifié)                                                 |
| Email         | VARCHAR(255)  | E-mail (unique, obligatoire)                                    |
| PhoneNumber   | VARCHAR(20)   | Numéro de téléphone (unique)                                    |
| PasswordHash  | VARCHAR(255)  | Hash du mot de passe (nullable si connexion externe uniquement) |
| AvatarURL     | VARCHAR(500)  | URL de l'avatar                                                 |
| HasPassword   | TINYINT(1)    | Le compte dispose d'un mot de passe local                       |
| EmailVerified | TINYINT(1)    | E-mail vérifié                                                  |
| PhoneVerified | TINYINT(1)    | Téléphone vérifié                                               |
| IsActive      | TINYINT(1)    | Compte actif                                                    |
| IsDeleted     | TINYINT(1)    | Suppression logique (soft delete)                               |
| LastLoginAt   | DATETIME      | Dernière connexion                                              |
| CreatedAt     | DATETIME      | Date de création                                                |
| UpdatedAt     | DATETIME      | Date de dernière modification                                   |

**Contraintes** : `PublicID`, `Email`, `PhoneNumber` uniques.
**Index notables** : `IXC_Users_Email_Login` (index composite optimisé pour la requête de login), `IXF_Users_Active_CreatedAt`.
**Relations** : table pivot de tout le schéma — référencée directement ou indirectement par la quasi-totalité des autres tables (profils, adresses, commandes, produits en tant que vendeur, etc.).

---

### 2.2. `UserExternalLogins` — Connexions externes (OAuth)

Permet à un utilisateur de se connecter via un fournisseur tiers (Google, Facebook, Apple…), en conservant les jetons et informations du fournisseur.

| Colonne              | Type          | Description                                              |
|----------------------|---------------|-------------------------------------------------------------|
| UserExternalLoginID  | INT (PK, AI)  | Identifiant de la liaison                                     |
| UserID               | INT (FK)      | Utilisateur concerné → `Users`                                |
| Provider             | TINYINT       | Fournisseur (codifié : Google, Facebook, Apple…)              |
| ProviderUserID       | VARCHAR(255)  | Identifiant de l'utilisateur chez le fournisseur               |
| Email                | VARCHAR(255)  | E-mail fourni par le fournisseur                                |
| IsEmailPrivateRelay  | TINYINT(1)    | E-mail relais privé (ex : Apple "Masquer mon e-mail")           |
| DisplayName          | VARCHAR(150)  | Nom affiché chez le fournisseur                                  |
| AvatarURL            | VARCHAR(500)  | Avatar fourni par le fournisseur                                 |
| RefreshToken         | VARCHAR(500)  | Jeton de rafraîchissement OAuth                                  |
| AccessTokenExpiresAt | DATETIME      | Expiration du jeton d'accès                                      |
| IsVerifiedEmail      | TINYINT(1)    | E-mail vérifié côté fournisseur                                  |
| LinkedAt             | DATETIME      | Date de liaison du compte                                        |
| LastLoginAt          | DATETIME      | Dernière connexion via ce fournisseur                            |
| RevokedAt            | DATETIME      | Date de révocation (déliaison) éventuelle                        |

**Contraintes** : couple `(Provider, ProviderUserID)` unique — un compte externe ne peut être lié qu'à un seul utilisateur.
**Suppression en cascade** si l'utilisateur est supprimé.

---

### 2.3. `UserRoles` — Attribution des rôles

Table de liaison **many-to-many** entre `Users` et `Roles`, avec traçabilité de l'attribution.

| Colonne     | Type          | Description                                     |
|-------------|---------------|-----------------------------------------------------|
| UserRoleID  | INT (PK, AI)  | Identifiant de l'attribution                          |
| UserID      | INT (FK)      | Utilisateur → `Users`                                 |
| RoleID      | INT (FK)      | Rôle → `Roles`                                         |
| AssignedAt  | DATETIME      | Date d'attribution                                      |
| AssignedBy  | INT (FK)      | Utilisateur ayant attribué le rôle → `Users` (nullable) |

**Contraintes** : couple `(UserID, RoleID)` unique (un rôle ne peut être attribué qu'une fois par utilisateur).

---

### 2.4. `VendorProfiles` — Profil vendeur

Extension du compte utilisateur pour les vendeurs : informations de boutique, statut de vérification (identité, activité, banque) et modération.

| Colonne            | Type           | Description                                                   |
|---------------------|----------------|-------------------------------------------------------------------|
| VendorProfileID     | INT (PK, AI)   | Identifiant du profil vendeur                                       |
| UserID              | INT (FK)       | Utilisateur associé → `Users` (unique, 1 profil vendeur / user)     |
| StoreName           | VARCHAR(150)   | Nom de la boutique                                                   |
| Description         | TEXT           | Description de la boutique                                          |
| LogoURL             | VARCHAR(500)   | Logo                                                                  |
| BannerURL           | VARCHAR(500)   | Bannière                                                              |
| Rating              | DECIMAL(3,2)   | Note moyenne                                                          |
| ReviewCount         | INT            | Nombre d'avis                                                         |
| IdentityVerified    | TINYINT(1)     | Identité du vendeur vérifiée                                          |
| BusinessVerified    | TINYINT(1)     | Activité/entreprise vérifiée                                          |
| BankVerified        | TINYINT(1)     | Coordonnées bancaires vérifiées                                       |
| VerificationStatus  | TINYINT        | Statut global de vérification (codifié)                              |
| IsApproved          | TINYINT(1)     | Boutique approuvée par la plateforme                                  |
| IsSuspended         | TINYINT(1)     | Boutique suspendue                                                    |
| SuspendedAt         | DATETIME       | Date de suspension                                                    |
| ApprovedAt          | DATETIME       | Date d'approbation                                                    |
| CreatedAt / UpdatedAt | DATETIME     | Horodatages standards                                                  |

**Relations** : référencée par `BankAccounts.VendorProfileID`, `OrderItems.VendorProfileID`. `Products.VendorID` référence directement `Users.UserID` (et non `VendorProfiles`).

---

### 2.5. `AdminProfiles` — Profil administrateur

Extension du compte pour les membres du back-office (équipe interne).

| Colonne          | Type          | Description                                |
|-------------------|---------------|-----------------------------------------------|
| AdminProfileID    | INT (PK, AI)  | Identifiant du profil admin                     |
| UserID            | INT (FK)      | Utilisateur associé → `Users` (unique)          |
| EmployeeNumber    | VARCHAR(50)   | Matricule employé (unique)                      |
| CIN               | VARCHAR(50)   | Numéro de carte d'identité nationale (unique)   |
| Position          | VARCHAR(100)  | Poste occupé                                    |
| Status            | TINYINT       | Statut de l'admin (codifié)                     |
| IdentityVerified  | TINYINT(1)    | Identité vérifiée                                |
| HireDate          | DATE          | Date d'embauche                                  |
| CreatedAt/UpdatedAt | DATETIME    | Horodatages standards                            |

**Usage métier** : les administrateurs référencés ailleurs (`Products.ValidatorID`, `RefusedBy`, `BlokedBy`) sont en réalité des `Users` — `AdminProfiles` n'est qu'une extension informative, pas la table référencée par les FK de modération.

---

### 2.6. `CustomerProfiles` — Profil client

Extension du compte pour les acheteurs (fidélité, préférences marketing).

| Colonne               | Type          | Description                                  |
|------------------------|---------------|--------------------------------------------------|
| CustomerProfileID      | INT (PK, AI)  | Identifiant du profil client                       |
| UserID                 | INT (FK)      | Utilisateur associé → `Users` (unique)             |
| LoyaltyPoints          | INT           | Points de fidélité cumulés                         |
| AcceptMarketingEmails  | TINYINT(1)    | Consentement marketing par e-mail                   |
| CreatedAt/UpdatedAt    | DATETIME      | Horodatages standards                               |

---

## 3. Adresses

### 3.1. `Addresses` — Adresses des utilisateurs

Table unique regroupant les adresses de livraison **et** de facturation d'un utilisateur (distinguées par les flags `IsDefaultBilling` / `IsDefaultShipping`), avec géolocalisation optionnelle.

| Colonne            | Type            | Description                                     |
|----------------------|-----------------|-----------------------------------------------------|
| AddressID           | INT (PK, AI)    | Identifiant de l'adresse                              |
| UserID              | INT (FK)        | Propriétaire → `Users`                                 |
| FullName            | VARCHAR(150)    | Nom complet du destinataire                             |
| Phone               | VARCHAR(20)     | Téléphone de contact                                    |
| Country             | VARCHAR(100)    | Pays (texte libre, pas de FK vers `Countries`)          |
| Region              | VARCHAR(100)    | Région/état                                             |
| City                | VARCHAR(100)    | Ville                                                    |
| PostalCode          | VARCHAR(20)     | Code postal                                              |
| AddressLine1/2      | VARCHAR(255)    | Lignes d'adresse                                         |
| Landmark            | VARCHAR(255)    | Point de repère                                          |
| Latitude/Longitude  | DECIMAL(10,7)   | Coordonnées GPS                                          |
| IsDefaultBilling    | TINYINT(1)      | Adresse de facturation par défaut                        |
| IsDefaultShipping   | TINYINT(1)      | Adresse de livraison par défaut                          |
| CreatedAt           | DATETIME        | Date de création                                          |

**Relations** : référencée par `Orders.BillingAddressID` et `Orders.ShippingAddressID`.
> ⚠️ Note de modélisation : `Country` est stocké en texte libre plutôt qu'en FK vers `Countries` — incohérence possible à corriger si l'on veut garantir des pays valides et normalisés.

---

## 4. Finance Vendeur

Cette section gère les moyens de paiement/encaissement, le portefeuille (solde) du vendeur, et l'historique de ses retraits.

### 4.1. `PaymentInformations` — Coordonnées de paiement

Coordonnées de paiement/encaissement enregistrées par un utilisateur (client ou vendeur), pour un moyen de paiement donné (IBAN, PayPal, wallet crypto…).

| Colonne              | Type           | Description                              |
|-----------------------|----------------|-----------------------------------------------|
| PaymentInformationID | INT (PK, AI)   | Identifiant                                     |
| UserID               | INT (FK)       | Utilisateur → `Users`                           |
| PaymentMethodID      | INT (FK)       | Moyen de paiement → `PaymentMethods`            |
| AccountName          | VARCHAR(150)   | Nom du titulaire du compte                       |
| AccountNumber        | VARCHAR(100)   | Numéro de compte                                 |
| IBAN                 | VARCHAR(50)    | IBAN                                              |
| SwiftCode            | VARCHAR(20)    | Code SWIFT/BIC                                   |
| PaypalEmail          | VARCHAR(255)   | E-mail PayPal                                    |
| WalletAddress        | VARCHAR(255)   | Adresse de portefeuille crypto                    |
| IsDefault            | TINYINT(1)     | Moyen par défaut pour cet utilisateur             |
| IsVerified           | TINYINT(1)     | Coordonnées vérifiées                             |
| CreatedAt            | DATETIME       | Date de création                                   |

---

### 4.2. `BankAccounts` — Portefeuille vendeur

Représente le **solde interne** (portefeuille) d'un vendeur sur la plateforme — pas un compte bancaire réel au sens strict, malgré son nom.

| Colonne              | Type            | Description                                       |
|-----------------------|-----------------|--------------------------------------------------------|
| BankAccountID        | INT (PK, AI)    | Identifiant                                              |
| VendorProfileID      | INT (FK)        | Vendeur associé → `VendorProfiles` (unique, 1 par vendeur)|
| CurrentBalance       | DECIMAL(14,2)   | Solde total actuel                                        |
| WithdrawableBalance  | DECIMAL(14,2)   | Solde disponible pour retrait                              |
| PendingBalance       | DECIMAL(14,2)   | Solde en attente (ex : période de garantie/litige)         |
| CurrencyCode         | CHAR(3)         | Devise (par défaut `MAD`)                                  |
| IsLocked             | TINYINT(1)      | Compte verrouillé (ex : suite à fraude)                    |
| CreatedAt/UpdatedAt  | DATETIME        | Horodatages standards                                       |

**Relations** : référencée par `WithdrawHistory.BankAccountID`.

---

### 4.3. `WithdrawHistory` — Historique des retraits

Journal des demandes de retrait effectuées par un vendeur depuis son portefeuille (`BankAccounts`).

| Colonne            | Type            | Description                                     |
|----------------------|-----------------|-----------------------------------------------------|
| WithdrawID          | INT (PK, AI)    | Identifiant de la demande                             |
| BankAccountID       | INT (FK)        | Portefeuille source → `BankAccounts`                   |
| PaymentMethodID     | INT (FK)        | Moyen utilisé pour le retrait → `PaymentMethods`        |
| Amount              | DECIMAL(14,2)   | Montant demandé                                         |
| ExternalReference   | VARCHAR(150)    | Référence externe (ex : transaction bancaire)           |
| Status              | TINYINT         | Statut du retrait (codifié : en attente/traité/rejeté…) |
| Notes               | VARCHAR(500)    | Notes internes                                           |
| RequestedAt         | DATETIME        | Date de la demande                                       |
| ProcessedAt         | DATETIME        | Date de traitement                                        |

---

## 5. Catalogue : Catégories, Attributs, Marques

### 5.1. `Categories` — Catégories produit

Arborescence de catégories (auto-référencée via `ParentCategoryID`), permettant une hiérarchie multi-niveaux (ex : Électronique > Téléphones > Smartphones).

| Colonne          | Type          | Description                                     |
|-------------------|---------------|-----------------------------------------------------|
| CategoryID       | INT (PK, AI)  | Identifiant de la catégorie                            |
| ParentCategoryID | INT (FK)      | Catégorie parente → `Categories` (auto-référence)      |
| Name             | VARCHAR(150)  | Nom                                                     |
| Slug             | VARCHAR(150)  | Slug URL (unique)                                       |
| IconURL          | VARCHAR(500)  | Icône                                                    |
| IsActive         | TINYINT(1)    | Catégorie active                                         |
| DisplayOrder     | INT           | Ordre d'affichage                                        |
| CreatedAt/UpdatedAt | DATETIME   | Horodatages standards                                     |

**Relations** : référencée par `ProductsConfigAttribute.CategoryID`, `ProductCategories.CategoryID`, `CategoryClosure`.

### 5.2. `CategoryClosure` — Table de fermeture transitive

Implémente le pattern **Closure Table** pour permettre des requêtes efficaces sur l'arborescence de catégories (retrouver tous les descendants ou ancêtres d'une catégorie sans requêtes récursives coûteuses).

| Colonne      | Type      | Description                                                |
|--------------|-----------|----------------------------------------------------------------|
| AncestorID   | INT (FK)  | Catégorie ancêtre → `Categories`                                 |
| DescendantID | INT (FK)  | Catégorie descendante → `Categories`                             |
| Depth        | INT       | Distance (nombre de niveaux) entre ancêtre et descendant          |

**Clé primaire composite** : `(AncestorID, DescendantID)`. Chaque catégorie possède aussi une ligne où elle est son propre ancêtre/descendant avec `Depth = 0`.

### 5.3. `Brands` — Marques

| Colonne      | Type          | Description                              |
|--------------|---------------|-----------------------------------------------|
| BrandID      | INT (PK, AI)  | Identifiant de la marque                        |
| Name         | VARCHAR(150)  | Nom de la marque                                 |
| Slug         | VARCHAR(150)  | Slug URL (unique)                                |
| LogoURL      | VARCHAR(500)  | Logo                                              |
| Website      | VARCHAR(255)  | Site web officiel                                 |
| Description  | TEXT          | Description                                       |
| CountryID    | INT (FK)      | Pays d'origine → `Countries`                       |
| IsActive     | TINYINT(1)    | Marque active                                      |
| CreatedAt/UpdatedAt | DATETIME | Horodatages standards                               |

**Relations** : référencée par `Models.BrandID`, `Products.BrandID`.

### 5.4. `Models` — Modèles

Modèles rattachés à une marque (ex : marque "Samsung" → modèle "Galaxy S24").

| Colonne      | Type          | Description                              |
|--------------|---------------|-----------------------------------------------|
| ModelID      | INT (PK, AI)  | Identifiant du modèle                            |
| BrandID      | INT (FK)      | Marque → `Brands`                                 |
| Name         | VARCHAR(150)  | Nom du modèle                                      |
| Code         | VARCHAR(50)   | Code interne (unique par marque)                   |
| Description  | TEXT          | Description                                         |
| ReleaseYear  | SMALLINT      | Année de sortie                                     |
| IsActive     | TINYINT(1)    | Modèle actif                                        |
| CreatedAt/UpdatedAt | DATETIME | Horodatages standards                                |

**Contraintes** : couple `(BrandID, Code)` unique.
**Relations** : référencée par `Products.ModelID`.

### 5.5. `ProductsConfigAttribute` — Attributs de configuration par catégorie

Définit les attributs configurables **spécifiques à une catégorie** (ex : pour "Vêtements" → attribut "Taille" ; pour "Électronique" → attribut "Puissance (W)").

| Colonne      | Type          | Description                                   |
|--------------|---------------|---------------------------------------------------|
| AttributeID  | INT (PK, AI)  | Identifiant de l'attribut                            |
| CategoryID   | INT (FK)      | Catégorie concernée → `Categories`                    |
| UnitID       | INT (FK)      | Unité de mesure associée → `Units` (optionnelle)      |
| Name         | VARCHAR(150)  | Nom de l'attribut                                      |
| DisplayOrder | INT           | Ordre d'affichage                                       |

**Relations** : référencée par `ConfigAttributeOptions.ProductsConfigAttributeID`, `ProductDetails.ProductsConfigAttributeID`.

### 5.6. `ConfigAttributeOptions` — Options de valeur pour un attribut

Valeurs possibles pour un attribut donné (ex : attribut "Taille" → options "S", "M", "L").

| Colonne                    | Type          | Description                                     |
|------------------------------|---------------|------------------------------------------------------|
| OptionID                    | INT (PK, AI)  | Identifiant de l'option                                |
| ProductsConfigAttributeID   | INT (FK)      | Attribut parent → `ProductsConfigAttribute`             |
| OptionLabel                 | VARCHAR(150)  | Libellé affiché                                          |
| OptionValue                 | VARCHAR(150)  | Valeur technique                                          |
| DisplayOrder                | INT           | Ordre d'affichage                                          |
| IsDefaultForAttribute       | TINYINT(1)    | Option par défaut pour l'attribut                          |

**Relations** : référencée par `ProductDetails.OptionID`.

---

## 6. Produits

### 6.1. `Products` — Fiches produit

Table centrale du catalogue. Un produit appartient à un vendeur (`VendorID`), passe par un **workflow de modération** (brouillon → validé → accepté / bloqué / refusé).

| Colonne          | Type            | Description                                                          |
|-------------------|-----------------|---------------------------------------------------------------------------|
| ProductID        | INT (PK, AI)    | Identifiant du produit                                                      |
| VendorID         | INT (FK)        | Vendeur → `Users`                                                            |
| BrandID          | INT (FK)        | Marque → `Brands` (nullable)                                                 |
| ModelID          | INT (FK)        | Modèle → `Models` (nullable)                                                 |
| Name             | VARCHAR(255)    | Nom du produit                                                                |
| Barcode          | VARCHAR(100)    | Code-barres (unique)                                                          |
| Description      | TEXT            | Description                                                                    |
| BasePrice        | DECIMAL(12,2)   | Prix de base                                                                   |
| Stock            | INT             | Quantité en stock                                                              |
| Status           | TINYINT         | 0=brouillon, 1=validé, 2=accepté, 3=bloqué                                     |
| CreatedAt/UpdatedAt/DeletedAt | DATETIME | Horodatages (suppression logique possible)                              |
| IsActive         | TINYINT(1)      | Produit actif (visible en vitrine)                                             |
| RefuseNotes / RefusedBy / RefuseAt / RefuseAttempt | — | Traçabilité d'un refus de modération (motif, modérateur, date, tentative n°) |
| ValidatorID / ValidationNotes / ValidationDate | — | Traçabilité de la validation (modérateur, notes, date)                  |
| IsBlocked / BlokedBy / BlockedDate / BlockedNotes | — | Traçabilité d'un blocage (motif, modérateur, date)                       |

**Relations sortantes** : `VendorID`, `RefusedBy`, `ValidatorID`, `BlokedBy` → tous vers `Users` (le modérateur est un utilisateur avec le rôle adéquat).
**Relations entrantes** : point d'ancrage de `ProductResources`, `ProductAllowedPayements`, `ProductDetails`, `ProductCategories`, `ProductTags`, `ProductSearchIndex`, `ProductRankingFactors`, `RegionalProductStats`, `CartItems`, `WishListItems`, `OrderItems`, `SearchTermProductStats`, `FAIT_EVENEMENT_CLIENT`, `FAIT_SCORE_CLIENT_PRODUIT`.
**Index notables** : `IXF_Products_Storefront` (vitrine), `IXF_Products_PendingValidation` (file de modération), `IX_Products_Vendor_Status` (tableau de bord vendeur).

---

### 6.2. `ProductResources` — Médias du produit

Fichiers/ressources associés à un produit (images, vidéos, documents), typés (`ResourcesTypes`) et rôlés (`ResourcesRoles`).

| Colonne         | Type          | Description                                     |
|------------------|---------------|-----------------------------------------------------|
| ID              | INT (PK, AI)  | Identifiant                                            |
| ProductID       | INT (FK)      | Produit → `Products`                                    |
| ResourcesPath   | VARCHAR(500)  | Chemin/URL du fichier                                   |
| ResourcesTypeID | INT (FK)      | Type → `ResourcesTypes`                                  |
| ResourceRoleID  | INT (FK)      | Rôle → `ResourcesRoles`                                  |

---

### 6.3. `ProductAllowedPayements` — Moyens de paiement autorisés par produit

Table de liaison **many-to-many** entre `Products` et `PaymentMethods`, permettant à un vendeur de restreindre les moyens de paiement acceptés pour un produit donné.

| Colonne           | Type          | Description                              |
|--------------------|---------------|-----------------------------------------------|
| ID                | INT (PK, AI)  | Identifiant                                     |
| ProductID         | INT (FK)      | Produit → `Products`                             |
| PayementMethodID  | INT (FK)      | Moyen de paiement → `PaymentMethods`             |

**Contraintes** : couple `(ProductID, PayementMethodID)` unique.

---

### 6.4. `ProductDetails` — Valeurs des attributs pour un produit

Stocke, pour chaque produit, la valeur choisie pour chaque attribut de configuration applicable (soit une option prédéfinie, soit une valeur libre).

| Colonne                    | Type          | Description                                              |
|------------------------------|---------------|----------------------------------------------------------|
| ProductDetailID             | INT (PK, AI)  | Identifiant                                                 |
| ProductID                   | INT (FK)      | Produit → `Products`                                         |
| ProductsConfigAttributeID   | INT (FK)      | Attribut → `ProductsConfigAttribute`                          |
| OptionID                    | INT (FK)      | Option choisie → `ConfigAttributeOptions` (nullable)          |
| CustomValue                 | VARCHAR(255)  | Valeur libre si aucune option prédéfinie ne convient           |

---

### 6.5. `ProductCategories` — Rattachement produit ↔ catégorie

Table de liaison **many-to-many** : un produit peut être classé dans plusieurs catégories, dont une désignée comme principale.

| Colonne    | Type       | Description                                |
|------------|------------|-------------------------------------------------|
| ProductID  | INT (FK)   | Produit → `Products`                              |
| CategoryID | INT (FK)   | Catégorie → `Categories`                           |
| IsPrimary  | TINYINT(1) | Catégorie principale du produit                    |

**Clé primaire composite** : `(ProductID, CategoryID)`.

---

### 6.6. `ProductTags` — Rattachement produit ↔ tag

Table de liaison **many-to-many** entre `Products` et `Tags`.

| Colonne    | Type      | Description                    |
|------------|-----------|------------------------------------|
| ProductID  | INT (FK)  | Produit → `Products`                 |
| TagID      | INT (FK)  | Tag → `Tags`                          |
| CreatedAt  | DATETIME  | Date d'association                    |

**Clé primaire composite** : `(ProductID, TagID)`.

---

## 7. Recherche & Classement

### 7.1. `ProductSearchIndex` — Index de recherche plein texte

Table dédiée à la recherche textuelle sur les produits, avec un index `FULLTEXT` MySQL sur `SearchText` (texte agrégé/pré-calculé à partir des champs pertinents du produit).

| Colonne       | Type      | Description                                        |
|----------------|-----------|---------------------------------------------------------|
| ProductID     | INT (PK)  | Produit → `Products` (1-1)                                |
| SearchText    | TEXT      | Texte indexé (nom, description, marque, etc. concaténés) |
| CategoryPath  | VARCHAR(500) | Chemin de catégorie dénormalisé (pour filtrage rapide) |
| LastIndexed   | DATETIME  | Date de dernière indexation                                |

---

### 7.2. `SearchDictionary` — Dictionnaire des termes de recherche

Référentiel des termes/expressions de recherche connus du système (produits, marques, catégories…), avec des métriques d'usage utilisées pour l'autocomplétion et le classement des suggestions.

| Colonne          | Type          | Description                                          |
|-------------------|---------------|----------------------------------------------------------|
| SearchTermID     | INT (PK, AI)  | Identifiant du terme                                        |
| DisplayText      | VARCHAR(255)  | Texte affiché                                                |
| NormalizedText   | VARCHAR(255)  | Texte normalisé (unique — pour dédupliquer variantes)        |
| SourceType       | TINYINT       | Origine du terme (ex : produit, marque, catégorie, libre)     |
| SourceID         | INT           | Identifiant de la source (polymorphe selon `SourceType`)       |
| Score            | DECIMAL(10,4) | Score de pertinence global                                     |
| SearchHitCount   | INT           | Nombre total de recherches                                     |
| SearchHitCount7d | INT           | Nombre de recherches sur 7 jours (tendance)                    |
| ResultCount      | INT           | Nombre de résultats habituellement retournés                    |
| LastSearchedAt   | DATETIME      | Dernière recherche                                              |
| IsActive         | TINYINT(1)    | Terme actif                                                     |
| CreatedAt/UpdatedAt | DATETIME   | Horodatages standards                                            |

**Relations** : référencée par `SearchSynonyms.MapsToSearchTermID`, `SearchTermProductStats.SearchTermID`.

---

### 7.3. `IPGeoLocations` — Géolocalisation par IP

Cache de résolution géographique d'adresses IP (évite un appel externe répété), avec expiration.

| Colonne          | Type          | Description                     |
|-------------------|---------------|-------------------------------------|
| IPGeoLocationID  | INT (PK, AI)  | Identifiant                            |
| IPAddress        | VARCHAR(45)   | Adresse IP (unique — IPv4/IPv6)         |
| CountryCode      | CHAR(2)       | Code pays résolu                        |
| Region           | VARCHAR(100)  | Région résolue                          |
| City             | VARCHAR(100)  | Ville résolue                            |
| Latitude/Longitude | DECIMAL(10,7) | Coordonnées GPS résolues                |
| ResolvedAt       | DATETIME      | Date de résolution                       |
| ExpiresAt        | DATETIME      | Date d'expiration du cache                |

**Relations** : référencée par `UserSearchHistory.IPGeoLocationID`.

---

### 7.4. `UserSearchHistory` — Historique de recherche utilisateur

Journal de toutes les recherches effectuées (connectées ou anonymes via `SessionID`), avec le produit éventuellement cliqué en résultat — base pour la personnalisation et l'analyse comportementale.

| Colonne          | Type          | Description                                        |
|-------------------|---------------|----------------------------------------------------------|
| UserSearchID     | INT (PK, AI)  | Identifiant de la recherche                                 |
| UserID           | INT (FK)      | Utilisateur → `Users` (nullable si anonyme)                  |
| SessionID        | VARCHAR(100)  | Identifiant de session (pour les visiteurs anonymes)          |
| SearchText       | VARCHAR(255)  | Texte recherché tel que saisi                                  |
| NormalizedText   | VARCHAR(255)  | Texte normalisé                                                 |
| ResultCount      | INT           | Nombre de résultats retournés                                   |
| ClickedProductID | INT (FK)      | Produit cliqué → `Products` (nullable)                          |
| IPAddress        | VARCHAR(45)   | Adresse IP d'origine                                             |
| IPGeoLocationID  | INT (FK)      | Géolocalisation résolue → `IPGeoLocations`                        |
| SearchedAt       | DATETIME      | Date/heure de la recherche                                        |

---

### 7.5. `SearchSynonyms` — Synonymes de recherche

Permet de faire correspondre des variantes/synonymes/fautes courantes vers un terme canonique du `SearchDictionary` (multi-langue via `LanguageCode`).

| Colonne             | Type          | Description                                        |
|-----------------------|---------------|----------------------------------------------------------|
| SynonymID            | INT (PK, AI)  | Identifiant                                                 |
| Term                 | VARCHAR(255)  | Terme saisi (variante)                                       |
| NormalizedTerm       | VARCHAR(255)  | Terme normalisé                                               |
| MapsToSearchTermID   | INT (FK)      | Terme canonique cible → `SearchDictionary`                     |
| LanguageCode         | VARCHAR(10)   | Code langue (défaut `fr`)                                      |
| IsActive             | TINYINT(1)    | Synonyme actif                                                 |
| CreatedAt            | DATETIME      | Date de création                                                |

**Contraintes** : couple `(NormalizedTerm, LanguageCode)` unique.

---

### 7.6. `SearchTermProductStats` — Statistiques terme ↔ produit

Mesure la performance d'un produit pour un terme de recherche donné (impressions, clics, achats) — alimente le classement des résultats de recherche.

| Colonne              | Type            | Description                                     |
|------------------------|-----------------|-----------------------------------------------------|
| SearchTermProductID   | INT (PK, AI)    | Identifiant                                            |
| SearchTermID          | INT (FK)        | Terme → `SearchDictionary`                              |
| ProductID             | INT (FK)        | Produit → `Products`                                     |
| ImpressionCount       | INT             | Nombre d'apparitions dans les résultats                  |
| ClickCount            | INT             | Nombre de clics                                           |
| PurchaseCount         | INT             | Nombre d'achats consécutifs                                |
| ClickThroughRate      | DECIMAL(8,5)    | Taux de clic (CTR)                                          |
| ConversionRate        | DECIMAL(8,5)    | Taux de conversion                                           |
| LastInteractionAt     | DATETIME        | Dernière interaction                                          |
| CreatedAt/UpdatedAt   | DATETIME        | Horodatages standards                                         |

**Contraintes** : couple `(SearchTermID, ProductID)` unique.

---

### 7.7. `ProductRankingFactors` — Facteurs de classement produit

Facteurs pré-calculés utilisés pour ordonner les produits en vitrine/recherche (ventes récentes, vues, disponibilité, mise en avant, fraîcheur), agrégés en un score final.

| Colonne                 | Type            | Description                                     |
|---------------------------|-----------------|-----------------------------------------------------|
| ProductRankingFactorID   | INT (PK, AI)    | Identifiant                                            |
| ProductID                | INT (FK)        | Produit → `Products` (unique, 1-1)                       |
| SalesCount30d            | INT             | Ventes sur 30 jours                                       |
| ViewCount30d              | INT             | Vues sur 30 jours                                         |
| InStock                   | TINYINT(1)      | En stock                                                   |
| StockLevel                | INT             | Niveau de stock                                            |
| IsFeatured                | TINYINT(1)      | Produit mis en avant                                       |
| FreshnessScore            | DECIMAL(8,4)    | Score de fraîcheur (nouveauté)                             |
| FinalRankingScore         | DECIMAL(10,4)   | Score final agrégé utilisé pour le tri                     |
| LastCalculatedAt          | DATETIME        | Date du dernier calcul                                      |

---

### 7.8. `RegionalProductStats` — Statistiques régionales par produit

Popularité d'un produit **par zone géographique** (pays/région), utile pour des tendances locales ("populaire près de chez vous").

| Colonne              | Type            | Description                                 |
|------------------------|-----------------|--------------------------------------------------|
| RegionalProductStatID | INT (PK, AI)    | Identifiant                                        |
| CountryCode           | CHAR(2)         | Code pays                                            |
| Region                | VARCHAR(100)    | Région                                                |
| ProductID             | INT (FK)        | Produit → `Products`                                   |
| ViewCount             | INT             | Nombre de vues dans la zone                             |
| PurchaseCount         | INT             | Nombre d'achats dans la zone                             |
| TrendScore            | DECIMAL(10,4)   | Score de tendance                                        |
| LastUpdatedAt         | DATETIME        | Dernière mise à jour                                      |

**Contraintes** : triplet `(CountryCode, Region, ProductID)` unique.

---

## 8. Panier & Liste de souhaits

### 8.1. `Carts` — Panier

Un panier par utilisateur (relation 1-1).

| Colonne     | Type          | Description                        |
|--------------|---------------|-----------------------------------------|
| CartID      | INT (PK, AI)  | Identifiant du panier                     |
| UserID      | INT (FK)      | Propriétaire → `Users` (unique)            |
| CreatedAt/UpdatedAt | DATETIME | Horodatages standards                        |

### 8.2. `CartItems` — Lignes de panier

| Colonne          | Type            | Description                                        |
|--------------------|-----------------|----------------------------------------------------------|
| CartItemID        | INT (PK, AI)    | Identifiant de la ligne                                     |
| CartID            | INT (FK)        | Panier → `Carts`                                              |
| ProductID         | INT (FK)        | Produit → `Products`                                           |
| ProductVariantID  | INT             | Variante du produit (référence libre, sans FK déclarée)         |
| Quantity          | DECIMAL(10,2)   | Quantité                                                        |
| UnitPrice         | DECIMAL(12,2)   | Prix unitaire au moment de l'ajout (figé)                        |
| CreatedAt         | DATETIME        | Date d'ajout                                                     |

**Contraintes** : triplet `(CartID, ProductID, ProductVariantID)` unique (pas de doublon de ligne pour un même produit/variante).

### 8.3. `WishLists` — Listes de souhaits

Un utilisateur peut posséder plusieurs listes (ex : "Ma liste", "Anniversaire"), l'une étant désignée par défaut.

| Colonne     | Type          | Description                              |
|--------------|---------------|-----------------------------------------------|
| WishListID  | INT (PK, AI)  | Identifiant de la liste                          |
| UserID      | INT (FK)      | Propriétaire → `Users`                            |
| Name        | VARCHAR(150)  | Nom de la liste (défaut "My Wishlist")             |
| IsDefault   | TINYINT(1)    | Liste par défaut                                   |
| CreatedAt   | DATETIME      | Date de création                                    |

### 8.4. `WishListItems` — Produits d'une liste de souhaits

| Colonne         | Type          | Description                            |
|-------------------|---------------|--------------------------------------------|
| WishListItemID   | INT (PK, AI)  | Identifiant                                   |
| WishListID       | INT (FK)      | Liste → `WishLists`                             |
| ProductID        | INT (FK)      | Produit → `Products`                             |
| CreatedAt        | DATETIME      | Date d'ajout                                      |

**Contraintes** : couple `(WishListID, ProductID)` unique.

---

## 9. Commandes & Paiements

> ⚙️ **Particularité technique** : `Orders` et `Payments` ont une **référence circulaire** (`Orders.PaymentID → Payments`, `Payments.OrderID → Orders`). Le script crée donc d'abord `Orders` **sans** la contrainte de clé étrangère sur `PaymentID`, puis crée `Payments`, puis ajoute la contrainte manquante via un `ALTER TABLE` — seule façon de résoudre une dépendance cyclique en SQL déclaratif.

### 9.1. `Orders` — Commandes

| Colonne             | Type            | Description                                         |
|-----------------------|-----------------|----------------------------------------------------------|
| OrderID              | INT (PK, AI)    | Identifiant de la commande                                  |
| UserID               | INT (FK)        | Client → `Users`                                              |
| BillingAddressID     | INT (FK)        | Adresse de facturation → `Addresses`                           |
| ShippingAddressID    | INT (FK)        | Adresse de livraison → `Addresses`                              |
| PaymentID            | INT (FK, nullable) | Paiement associé → `Payments` (ajouté après coup)           |
| OrderStatusID        | INT (FK)        | Statut → `OrderStatus`                                          |
| OrderNumber          | VARCHAR(50)     | Numéro de commande (unique, lisible)                             |
| Subtotal             | DECIMAL(12,2)   | Sous-total (hors frais/remise/taxe)                              |
| ShippingFee          | DECIMAL(12,2)   | Frais de livraison                                                |
| Discount             | DECIMAL(12,2)   | Remise appliquée                                                   |
| Tax                  | DECIMAL(12,2)   | Taxe                                                                |
| Total                | DECIMAL(12,2)   | Montant total                                                        |
| Currency             | CHAR(3)         | Devise (défaut `MAD`)                                                 |
| Notes                | VARCHAR(500)    | Notes libres                                                           |
| OrderedAt/UpdatedAt  | DATETIME        | Horodatages standards                                                  |

**Note** : une commande peut contenir des articles de **plusieurs vendeurs différents** (voir `OrderItems.VendorProfileID`), le paiement/adresses étant gérés au niveau global de la commande.

### 9.2. `Payments` — Paiements

| Colonne             | Type            | Description                                     |
|-----------------------|-----------------|-----------------------------------------------------|
| PaymentID            | INT (PK, AI)    | Identifiant du paiement                                |
| OrderID              | INT (FK)        | Commande → `Orders`                                      |
| PaymentMethodID      | INT (FK)        | Moyen de paiement → `PaymentMethods`                      |
| Amount               | DECIMAL(12,2)   | Montant payé                                                |
| Currency             | CHAR(3)         | Devise                                                       |
| TransactionID        | VARCHAR(150)    | Identifiant de transaction (unique)                          |
| ProviderReference    | VARCHAR(150)    | Référence chez le prestataire de paiement                     |
| Status               | TINYINT         | Statut du paiement (codifié)                                  |
| PaidAt               | DATETIME        | Date de paiement effectif                                      |
| CreatedAt            | DATETIME        | Date de création                                                |

### 9.3. `OrderItems` — Lignes de commande

Détail des produits commandés, ligne par ligne, avec le vendeur associé (permet la répartition multi-vendeurs d'une même commande).

| Colonne           | Type            | Description                                        |
|---------------------|-----------------|----------------------------------------------------------|
| OrderItemID        | INT (PK, AI)    | Identifiant de la ligne                                      |
| OrderID            | INT (FK)        | Commande → `Orders`                                           |
| ProductID          | INT (FK)        | Produit → `Products`                                           |
| ProductVariantID   | INT             | Variante (référence libre, sans FK déclarée)                    |
| VendorProfileID    | INT (FK)        | Vendeur → `VendorProfiles`                                       |
| Quantity           | DECIMAL(10,2)   | Quantité commandée                                                |
| UnitPrice          | DECIMAL(12,2)   | Prix unitaire figé au moment de la commande                       |
| Discount           | DECIMAL(12,2)   | Remise sur la ligne                                                |
| Tax                | DECIMAL(12,2)   | Taxe sur la ligne                                                   |
| Total              | DECIMAL(12,2)   | Total de la ligne                                                    |

---

## 10. Notifications

### 10.1. `Notifications` — Notifications utilisateur

Notification concrète envoyée/affichée à un utilisateur, instanciée à partir d'un `NotificationType`, avec une charge utile JSON libre et un lien optionnel vers une entité métier (commande, produit…) via un couple polymorphe `(RelatedEntityType, RelatedEntityID)`.

| Colonne              | Type          | Description                                            |
|------------------------|---------------|--------------------------------------------------------------|
| NotificationID        | INT (PK, AI)  | Identifiant                                                     |
| UserID                | INT (FK)      | Destinataire → `Users`                                            |
| NotificationTypeID    | INT (FK)      | Type → `NotificationTypes`                                         |
| Title                 | VARCHAR(255)  | Titre (généré depuis le template)                                   |
| Body                  | VARCHAR(1000) | Corps du message                                                     |
| DataPayload           | JSON          | Données additionnelles structurées                                   |
| RelatedEntityType     | VARCHAR(50)   | Type d'entité liée (ex : "Order", "Product") — clé polymorphe        |
| RelatedEntityID       | INT           | Identifiant de l'entité liée — clé polymorphe                        |
| IsRead                | TINYINT(1)    | Notification lue                                                      |
| ReadAt                | DATETIME      | Date de lecture                                                        |
| CreatedAt             | DATETIME      | Date de création                                                       |

### 10.2. `UserDevices` — Appareils utilisateur (push)

Appareils enregistrés pour l'envoi de notifications push (jeton FCM).

| Colonne       | Type          | Description                                  |
|----------------|---------------|--------------------------------------------------|
| UserDeviceID  | INT (PK, AI)  | Identifiant de l'appareil                           |
| UserID        | INT (FK)      | Utilisateur → `Users`                                |
| FCMToken      | VARCHAR(255)  | Jeton Firebase Cloud Messaging (unique)               |
| DeviceType    | TINYINT       | Type d'appareil (codifié : iOS/Android/Web…)          |
| DeviceModel   | VARCHAR(150)  | Modèle de l'appareil                                   |
| AppVersion    | VARCHAR(20)   | Version de l'application installée                     |
| IsActive      | TINYINT(1)    | Appareil actif                                          |
| LastUsedAt    | DATETIME      | Dernière utilisation                                     |
| CreatedAt     | DATETIME      | Date d'enregistrement                                     |

### 10.3. `UserNotificationPreferences` — Préférences de notification

Permet à un utilisateur de désactiver/activer le push pour un type de notification donné (si `NotificationTypes.IsUserConfigurable = 1`).

| Colonne                        | Type          | Description                                     |
|----------------------------------|---------------|-----------------------------------------------------|
| UserNotificationPreferenceID    | INT (PK, AI)  | Identifiant                                            |
| UserID                          | INT (FK)      | Utilisateur → `Users`                                    |
| NotificationTypeID              | INT (FK)      | Type de notification → `NotificationTypes`                |
| PushEnabled                     | TINYINT(1)    | Push activé pour ce type                                    |
| UpdatedAt                       | DATETIME      | Date de dernière modification                                |

**Contraintes** : couple `(UserID, NotificationTypeID)` unique.

### 10.4. `NotificationDeliveryLog` — Journal de livraison des notifications

Trace chaque tentative d'envoi d'une notification vers un appareil précis (succès/échec), utile pour le diagnostic des problèmes de livraison push.

| Colonne          | Type          | Description                                     |
|--------------------|---------------|-----------------------------------------------------|
| DeliveryLogID     | INT (PK, AI)  | Identifiant                                            |
| NotificationID    | INT (FK)      | Notification → `Notifications`                          |
| UserDeviceID      | INT (FK)      | Appareil cible → `UserDevices`                           |
| Status            | TINYINT       | Statut de livraison (codifié : succès/échec…)             |
| ErrorMessage      | VARCHAR(500)  | Message d'erreur éventuel                                  |
| AttemptedAt       | DATETIME      | Date de la tentative                                         |

---

## 11. Moteur de recommandation (tables de faits)

> 🇫🇷 Comme noté en section 1, ces tables suivent une convention de nommage **snake_case / français**, typique d'un modèle en étoile (schéma décisionnel) — probablement conçu comme un module analytique séparé, alimentant un système de recommandation basé sur des scores comportementaux.

### 11.1. `FAIT_EVENEMENT_CLIENT` — Fait : événement client

Table de faits enregistrant **chaque événement individuel** d'interaction d'un utilisateur avec un produit (vue, ajout au panier, achat, etc.), avec le score associé au type d'événement.

| Colonne             | Type          | Description                                              |
|-----------------------|---------------|----------------------------------------------------------------|
| id_evenement         | INT (PK, AI)  | Identifiant de l'événement                                        |
| id_utilisateur       | INT (FK)      | Utilisateur → `Users`                                              |
| id_annonce           | INT (FK)      | Produit concerné → `Products`                                      |
| id_type_evenement    | INT (FK)      | Type d'événement → `DIM_TYPE_EVENEMENT`                              |
| score                | INT           | Score attribué à cet événement précis                                |
| date_evenement       | DATETIME      | Date/heure de l'événement                                             |

**Usage** : table de log détaillé (grain le plus fin), destinée à être **agrégée** dans `FAIT_SCORE_CLIENT_PRODUIT`.

### 11.2. `FAIT_SCORE_CLIENT_PRODUIT` — Fait : score client/produit (agrégé)

Table de faits **agrégée** : score cumulé d'affinité entre un utilisateur et un produit, recalculé/mis à jour à partir des événements de `FAIT_EVENEMENT_CLIENT` — c'est cette table qui alimente concrètement le moteur de recommandation ("produits susceptibles d'intéresser cet utilisateur").

| Colonne                | Type          | Description                                       |
|--------------------------|---------------|---------------------------------------------------------|
| id                      | INT (PK, AI)  | Identifiant                                                |
| id_utilisateur          | INT (FK)      | Utilisateur → `Users`                                        |
| id_annonce              | INT (FK)      | Produit → `Products`                                          |
| score_total             | INT           | Score cumulé d'affinité utilisateur/produit                    |
| derniere_mise_a_jour    | DATETIME      | Date de dernier recalcul                                        |

**Contraintes** : couple `(id_utilisateur, id_annonce)` unique — un seul score cumulé par paire utilisateur/produit.

---

## Annexe — Conventions générales observées dans le script

- **Moteur de stockage** : `InnoDB` partout (support des transactions et clés étrangères).
- **Jeu de caractères** : `utf8mb4` / `utf8mb4_unicode_ci` (support complet Unicode, y compris emojis).
- **Suppression logique (soft delete)** : présente sur `Users` (`IsDeleted`) et `Products` (`DeletedAt`), mais absente ailleurs — à généraliser si le besoin existe sur d'autres entités.
- **Champs booléens** : modélisés en `TINYINT(1)` (convention MySQL classique, pas de type `BOOLEAN` natif).
- **Horodatages** : quasi-systématiques (`CreatedAt`, souvent `UpdatedAt` avec `ON UPDATE CURRENT_TIMESTAMP`).
- **Index composites préfixés** :
  - `IX_` : index simple de recherche/jointure ;
  - `IXF_` : index de filtrage (souvent sur des colonnes de statut/flags) ;
  - `IXC_` : index composite optimisé pour une requête précise (couvrant) ;
  - `UX_` : contrainte d'unicité ;
  - `FK_` : contrainte de clé étrangère ;
  - `FTX_` : index plein texte (`FULLTEXT`).
- **`ProductVariantID`** (dans `CartItems` et `OrderItems`) est stocké sans contrainte de clé étrangère déclarée : soit la table des variantes n'est pas encore présente dans ce script, soit la contrainte a été volontairement omise (point à clarifier).
- **Incohérence de nommage repérée** : `Addresses.Country` en texte libre vs. l'existence d'une table `Countries` normalisée par ailleurs (voir section 3).
