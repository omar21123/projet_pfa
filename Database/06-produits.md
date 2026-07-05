# Documentation du schéma — Marketplace Platform (MySQL 8.0)

## Section : Produits

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
