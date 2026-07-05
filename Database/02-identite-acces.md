# Documentation du schéma — Marketplace Platform (MySQL 8.0)

## Section : Identité & Accès

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
