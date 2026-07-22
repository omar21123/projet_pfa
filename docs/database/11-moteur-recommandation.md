# Documentation du schéma — Marketplace Platform (MySQL 8.0)

## Section : Moteur de recommandation

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
