# Documentation du schéma — Marketplace Platform (MySQL 8.0)

## Section : Panier & Liste de souhaits

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
