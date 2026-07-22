# Module 1 — Identité & Accès

## Objectif

Gère qui est l'utilisateur, comment il s'authentifie, et quel rôle il joue sur la plateforme (client, vendeur, admin). C'est le module fondation : toutes les autres tables du schéma pointent, directement ou indirectement, vers `Users`.

## Tables

### `Users`
Table centrale. Un enregistrement par personne physique inscrite, quel que soit son rôle.

- `PublicID` (UUID) — identifiant exposé publiquement/aux API externes, jamais `UserID` (auto-increment) pour éviter l'énumération.
- `HasPassword` — `false` si le compte n'existe que via OAuth (Google/Apple), utile pour savoir si on doit proposer "mot de passe oublié".
- `IsActive` / `IsDeleted` — deux flags distincts : un compte peut être désactivé temporairement (`IsActive = 0`) sans être supprimé (`IsDeleted = 0`), pour du soft-ban par exemple.

### `UserExternalLogins`
Comptes OAuth liés (Google, Apple). Un `User` peut avoir plusieurs providers liés.

- `IsEmailPrivateRelay` — spécifique à "Sign in with Apple", qui peut masquer l'email réel derrière un relay. Important à savoir avant d'envoyer des emails transactionnels à cette adresse.

### `Roles` / `UserRoles`
Système de rôles many-to-many. `IsSystem = 1` marque les rôles non supprimables (Admin, Vendor, Customer) par opposition à d'éventuels rôles custom futurs.

### `VendorProfiles`
Profil vendeur, en relation 1:1 avec `Users`. Ne contient que ce qui est spécifique au fait d'être vendeur (boutique, vérifications, note).

- `VerificationStatus` + trois flags (`IdentityVerified`, `BusinessVerified`, `BankVerified`) — permet de savoir précisément **quelle étape** de vérification bloque encore l'approbation.
- `IsApproved` / `IsSuspended` — un vendeur approuvé peut être suspendu sans perdre son approbation historique.

### `AdminProfiles`
Profil back-office, 1:1 avec `Users`. Contient les infos RH légères (numéro employé, CIN, poste).

### `CustomerProfiles`
Profil client, 1:1 avec `Users`. Volontairement minimaliste (points fidélité, préférence marketing) — tout le reste (adresses, panier, commandes) vit dans ses propres modules.

## Règles métier clés

- Un `User` a **au plus un** profil de chaque type (`VendorProfiles`, `AdminProfiles`, `CustomerProfiles`), mais rien n'empêche techniquement qu'un même compte soit à la fois client ET vendeur — à valider selon le besoin produit.
- La suppression d'un `User` supprime en cascade tous ses profils, connexions externes et rôles (`ON DELETE CASCADE`). En pratique, avec `IsDeleted`, la suppression physique ne devrait quasiment jamais arriver.

## Relations sortantes vers d'autres modules

- `Users.VendorID` → `Products` (Catalogue)
- `Users.UserID` → `Addresses`, `Orders`, `Carts`, `WishLists`, `Notifications`, `UserDevices`
- `VendorProfiles.VendorProfileID` → `BankAccounts` (Finance Vendeur), `OrderItems` (Commandes)

## Index & contraintes

Voir `README_indexation.md`, section "1. Identité & Accès" pour le détail complet (unicité `PublicID`/`Email`/`PhoneNumber`, index de couverture pour le login, etc.).
