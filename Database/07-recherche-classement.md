# Documentation du schéma — Marketplace Platform (MySQL 8.0)

## Section : Recherche & Classement

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
