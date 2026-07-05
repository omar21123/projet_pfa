# Documentation du schéma — Marketplace Platform (MySQL 8.0)

## Section : Notifications

## 10. Notifications

### 10.1. `Notifications` — Notifications utilisateur

Notification concrète envoyée/affichée à un utilisateur, instanciée à partir d'un `NotificationType`, avec une charge utile JSON libre et un lien optionnel vers une entité métier (commande, produit…) via un couple polymorphe `(RelatedEntityType, RelatedEntityID)`.

| Colonne              | Type          | Description                                            |
|------------------------|---------------|--------------------------------------------------------------|
| NotificationID        | INT (PK, AI)  | Identifiant                                                     |
| UserID                | INT (FK)      | Destinataire → `Users`                                            |
| NotificationTypeID    | INT (FK)      | Type → `NotificationTypes`                                         |
| Title                 | VARCHAR(255)  | Titre (généré depuis le template)                                   |
| Body                  | VARCHAR(1000) | Corps du message                                                     |
| DataPayload           | JSON          | Données additionnelles structurées                                   |
| RelatedEntityType     | VARCHAR(50)   | Type d'entité liée (ex : "Order", "Product") — clé polymorphe        |
| RelatedEntityID       | INT           | Identifiant de l'entité liée — clé polymorphe                        |
| IsRead                | TINYINT(1)    | Notification lue                                                      |
| ReadAt                | DATETIME      | Date de lecture                                                        |
| CreatedAt             | DATETIME      | Date de création                                                       |

### 10.2. `UserDevices` — Appareils utilisateur (push)

Appareils enregistrés pour l'envoi de notifications push (jeton FCM).

| Colonne       | Type          | Description                                  |
|----------------|---------------|--------------------------------------------------|
| UserDeviceID  | INT (PK, AI)  | Identifiant de l'appareil                           |
| UserID        | INT (FK)      | Utilisateur → `Users`                                |
| FCMToken      | VARCHAR(255)  | Jeton Firebase Cloud Messaging (unique)               |
| DeviceType    | TINYINT       | Type d'appareil (codifié : iOS/Android/Web…)          |
| DeviceModel   | VARCHAR(150)  | Modèle de l'appareil                                   |
| AppVersion    | VARCHAR(20)   | Version de l'application installée                     |
| IsActive      | TINYINT(1)    | Appareil actif                                          |
| LastUsedAt    | DATETIME      | Dernière utilisation                                     |
| CreatedAt     | DATETIME      | Date d'enregistrement                                     |

### 10.3. `UserNotificationPreferences` — Préférences de notification

Permet à un utilisateur de désactiver/activer le push pour un type de notification donné (si `NotificationTypes.IsUserConfigurable = 1`).

| Colonne                        | Type          | Description                                     |
|----------------------------------|---------------|-----------------------------------------------------|
| UserNotificationPreferenceID    | INT (PK, AI)  | Identifiant                                            |
| UserID                          | INT (FK)      | Utilisateur → `Users`                                    |
| NotificationTypeID              | INT (FK)      | Type de notification → `NotificationTypes`                |
| PushEnabled                     | TINYINT(1)    | Push activé pour ce type                                    |
| UpdatedAt                       | DATETIME      | Date de dernière modification                                |

**Contraintes** : couple `(UserID, NotificationTypeID)` unique.

### 10.4. `NotificationDeliveryLog` — Journal de livraison des notifications

Trace chaque tentative d'envoi d'une notification vers un appareil précis (succès/échec), utile pour le diagnostic des problèmes de livraison push.

| Colonne          | Type          | Description                                     |
|--------------------|---------------|-----------------------------------------------------|
| DeliveryLogID     | INT (PK, AI)  | Identifiant                                            |
| NotificationID    | INT (FK)      | Notification → `Notifications`                          |
| UserDeviceID      | INT (FK)      | Appareil cible → `UserDevices`                           |
| Status            | TINYINT       | Statut de livraison (codifié : succès/échec…)             |
| ErrorMessage      | VARCHAR(500)  | Message d'erreur éventuel                                  |
| AttemptedAt       | DATETIME      | Date de la tentative                                         |
