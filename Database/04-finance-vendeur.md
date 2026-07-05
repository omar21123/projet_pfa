# Documentation du schéma — Marketplace Platform (MySQL 8.0)

## Section : Finance Vendeur

## 4. Finance Vendeur

Cette section gère les moyens de paiement/encaissement, le portefeuille (solde) du vendeur, et l'historique de ses retraits.

### 4.1. `PaymentInformations` — Coordonnées de paiement

Coordonnées de paiement/encaissement enregistrées par un utilisateur (client ou vendeur), pour un moyen de paiement donné (IBAN, PayPal, wallet crypto…).

| Colonne              | Type           | Description                              |
|-----------------------|----------------|-----------------------------------------------|
| PaymentInformationID | INT (PK, AI)   | Identifiant                                     |
| UserID               | INT (FK)       | Utilisateur → `Users`                           |
| PaymentMethodID      | INT (FK)       | Moyen de paiement → `PaymentMethods`            |
| AccountName          | VARCHAR(150)   | Nom du titulaire du compte                       |
| AccountNumber        | VARCHAR(100)   | Numéro de compte                                 |
| IBAN                 | VARCHAR(50)    | IBAN                                              |
| SwiftCode            | VARCHAR(20)    | Code SWIFT/BIC                                   |
| PaypalEmail          | VARCHAR(255)   | E-mail PayPal                                    |
| WalletAddress        | VARCHAR(255)   | Adresse de portefeuille crypto                    |
| IsDefault            | TINYINT(1)     | Moyen par défaut pour cet utilisateur             |
| IsVerified           | TINYINT(1)     | Coordonnées vérifiées                             |
| CreatedAt            | DATETIME       | Date de création                                   |

---

### 4.2. `BankAccounts` — Portefeuille vendeur

Représente le **solde interne** (portefeuille) d'un vendeur sur la plateforme — pas un compte bancaire réel au sens strict, malgré son nom.

| Colonne              | Type            | Description                                       |
|-----------------------|-----------------|--------------------------------------------------------|
| BankAccountID        | INT (PK, AI)    | Identifiant                                              |
| VendorProfileID      | INT (FK)        | Vendeur associé → `VendorProfiles` (unique, 1 par vendeur)|
| CurrentBalance       | DECIMAL(14,2)   | Solde total actuel                                        |
| WithdrawableBalance  | DECIMAL(14,2)   | Solde disponible pour retrait                              |
| PendingBalance       | DECIMAL(14,2)   | Solde en attente (ex : période de garantie/litige)         |
| CurrencyCode         | CHAR(3)         | Devise (par défaut `MAD`)                                  |
| IsLocked             | TINYINT(1)      | Compte verrouillé (ex : suite à fraude)                    |
| CreatedAt/UpdatedAt  | DATETIME        | Horodatages standards                                       |

**Relations** : référencée par `WithdrawHistory.BankAccountID`.

---

### 4.3. `WithdrawHistory` — Historique des retraits

Journal des demandes de retrait effectuées par un vendeur depuis son portefeuille (`BankAccounts`).

| Colonne            | Type            | Description                                     |
|----------------------|-----------------|-----------------------------------------------------|
| WithdrawID          | INT (PK, AI)    | Identifiant de la demande                             |
| BankAccountID       | INT (FK)        | Portefeuille source → `BankAccounts`                   |
| PaymentMethodID     | INT (FK)        | Moyen utilisé pour le retrait → `PaymentMethods`        |
| Amount              | DECIMAL(14,2)   | Montant demandé                                         |
| ExternalReference   | VARCHAR(150)    | Référence externe (ex : transaction bancaire)           |
| Status              | TINYINT         | Statut du retrait (codifié : en attente/traité/rejeté…) |
| Notes               | VARCHAR(500)    | Notes internes                                           |
| RequestedAt         | DATETIME        | Date de la demande                                       |
| ProcessedAt         | DATETIME        | Date de traitement                                        |
