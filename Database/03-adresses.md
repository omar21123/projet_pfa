# Documentation du schéma — Marketplace Platform (MySQL 8.0)

## Section : Adresses

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
