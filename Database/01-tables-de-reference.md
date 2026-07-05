# Documentation du schéma — Marketplace Platform (MySQL 8.0)

## Section : Tables de référence

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
