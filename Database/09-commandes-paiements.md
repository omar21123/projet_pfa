# Documentation du schéma — Marketplace Platform (MySQL 8.0)

## Section : Commandes & Paiements

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
