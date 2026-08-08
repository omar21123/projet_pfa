# Documentation du schéma — Marketplace Platform (MySQL 8.0)

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
