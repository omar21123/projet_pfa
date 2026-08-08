# Documentation du schéma — Marketplace Platform (MySQL 8.0)

## Section : Catalogue

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
