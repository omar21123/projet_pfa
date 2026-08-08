## Database Schema
```mermaid
erDiagram

%%====================================================
%% USERS
%%====================================================

Users {
    INT UserID PK
    UUID PublicID
    NVARCHAR FirstName
    NVARCHAR LastName
    NVARCHAR DisplayName
    DATE BirthDate
    TINYINT Gender
    NVARCHAR Email
    NVARCHAR PhoneNumber
    NVARCHAR PasswordHash
    NVARCHAR AvatarURL
    BIT HasPassword "OAuth"
    BIT EmailVerified
    BIT PhoneVerified
    BIT IsActive
    BIT IsDeleted
    DATETIME LastLoginAt
    DATETIME CreatedAt
    DATETIME UpdatedAt
}
UserExternalLogins {
        INT UserExternalLoginID PK
        INT UserID FK

        TINYINT Provider
        NVARCHAR ProviderUserID

        NVARCHAR Email
        BIT IsEmailPrivateRelay

        NVARCHAR DisplayName
        NVARCHAR AvatarURL

        NVARCHAR RefreshToken
        DATETIME AccessTokenExpiresAt

        BIT IsVerifiedEmail

        DATETIME LinkedAt
        DATETIME LastLoginAt
        DATETIME RevokedAt
    }
%%====================================================
%% ROLES
%%====================================================

Roles {
    INT RoleID PK
    NVARCHAR Name
    NVARCHAR Code
    NVARCHAR Description
    BIT IsSystem
    DATETIME CreatedAt
}

%%====================================================
%% USER ROLES
%%====================================================

UserRoles {
    INT UserRoleID PK
    INT UserID FK
    INT RoleID FK
    DATETIME AssignedAt
    INT AssignedBy FK
}

%%====================================================
%% VENDOR PROFILE
%%====================================================

VendorProfiles {
    INT VendorProfileID PK
    INT UserID FK

    NVARCHAR StoreName
    NVARCHAR Description

    NVARCHAR LogoURL
    NVARCHAR BannerURL

    DECIMAL Rating
    INT ReviewCount

    BIT IdentityVerified
    BIT BusinessVerified
    BIT BankVerified

    TINYINT VerificationStatus

    BIT IsApproved
    BIT IsSuspended
 DATETIME SuspendedAt
    DATETIME ApprovedAt
    DATETIME CreatedAt
    DATETIME UpdatedAt
}

%%====================================================
%% ADMIN PROFILE
%%====================================================

AdminProfiles {
    INT AdminProfileID PK
    INT UserID FK

    NVARCHAR EmployeeNumber
    NVARCHAR CIN
    NVARCHAR Position

    TINYINT Status

    BIT IdentityVerified

    DATETIME HireDate

    DATETIME CreatedAt
    DATETIME UpdatedAt
}

%%====================================================
%% CUSTOMER PROFILE
%%====================================================

CustomerProfiles {
    INT CustomerProfileID PK
    INT UserID FK

    INT LoyaltyPoints

    BIT AcceptMarketingEmails

    DATETIME CreatedAt
    DATETIME UpdatedAt
}

%%====================================================
%% ADDRESSES
%%====================================================

Addresses {
    INT AddressID PK
    INT UserID FK
    NVARCHAR FullName
    NVARCHAR Phone
    NVARCHAR Country
    NVARCHAR Region
    NVARCHAR City
    NVARCHAR PostalCode
    NVARCHAR AddressLine1
    NVARCHAR AddressLine2
    NVARCHAR Landmark
    DECIMAL Latitude
    DECIMAL Longitude
    BIT IsDefaultBilling
    BIT IsDefaultShipping
    DATETIME CreatedAt
}
    %%====================================================
    %% NOTIFICATIONS
    %%====================================================

    NotificationTypes {
        INT NotificationTypeID PK
        NVARCHAR Code
        TINYINT Category
        NVARCHAR TitleTemplate
        NVARCHAR BodyTemplate
        BIT DefaultPushEnabled
        BIT IsUserConfigurable
        BIT IsActive
        DATETIME CreatedAt
    }

    Notifications {
        INT NotificationID PK
        INT UserID FK
        INT NotificationTypeID FK
        NVARCHAR Title
        NVARCHAR Body
        NVARCHAR DataPayload
        NVARCHAR RelatedEntityType
        INT RelatedEntityID
        BIT IsRead
        DATETIME ReadAt
        DATETIME CreatedAt
    }

    UserDevices {
        INT UserDeviceID PK
        INT UserID FK
        NVARCHAR FCMToken
        TINYINT DeviceType
        NVARCHAR DeviceModel
        NVARCHAR AppVersion
        BIT IsActive
        DATETIME LastUsedAt
        DATETIME CreatedAt
    }

    UserNotificationPreferences {
        INT UserNotificationPreferenceID PK
        INT UserID FK
        INT NotificationTypeID FK
        BIT PushEnabled
        DATETIME UpdatedAt
    }

    NotificationDeliveryLog {
        INT DeliveryLogID PK
        INT NotificationID FK
        INT UserDeviceID FK
        TINYINT Status
        NVARCHAR ErrorMessage
        DATETIME AttemptedAt
    }
%%====================================================
%% PAYMENT METHODS
%%====================================================

PaymentMethods {
    INT PaymentMethodID PK
    NVARCHAR Name
    NVARCHAR Code
    NVARCHAR IconURL
    Money withdraw_Tax
    BIT IsOnline
    BIT IsActive
    INT DisplayOrder
}

%%====================================================
%% PAYMENT INFORMATIONS
%%====================================================

PaymentInformations {
    INT PaymentInformationID PK
    INT UserID FK
    INT PaymentMethodID FK
    NVARCHAR AccountName
    NVARCHAR AccountNumber
    NVARCHAR IBAN
    NVARCHAR SwiftCode
    NVARCHAR PaypalEmail
    NVARCHAR WalletAddress
    BIT IsDefault
    BIT IsVerified
    DATETIME CreatedAt
}

%%====================================================
%% BANK ACCOUNT
%%====================================================

BankAccounts {
    INT BankAccountID PK
    INT VendorProfileID FK
    DECIMAL CurrentBalance
    DECIMAL WithdrawableBalance
    DECIMAL PendingBalance
    NVARCHAR CurrencyCode
    BIT IsLocked
    DATETIME CreatedAt
    DATETIME UpdatedAt
}

%%====================================================
%% WITHDRAW HISTORY
%%====================================================

WithdrawHistory {
    INT WithdrawID PK
    INT BankAccountID FK
    INT PaymentMethodID FK
    DECIMAL Amount
    NVARCHAR ExternalReference
    TINYINT Status
    NVARCHAR Notes
    DATETIME RequestedAt
    DATETIME ProcessedAt
}

%%====================================================
%% CART
%%====================================================

Carts {
    INT CartID PK
    INT UserID FK
    DATETIME CreatedAt
    DATETIME UpdatedAt
}

CartItems {
    INT CartItemID PK
    INT CartID FK
    INT ProductID FK
    INT ProductVariantID FK
    DECIMAL Quantity
    DECIMAL UnitPrice
    DATETIME CreatedAt
}

%%====================================================
%% WISHLISTS
%%====================================================

WishLists {
    INT WishListID PK
    INT UserID FK
    NVARCHAR Name
    BIT IsDefault
    DATETIME CreatedAt
}

WishListItems {
    INT WishListItemID PK
    INT WishListID FK
    INT ProductID FK
    DATETIME CreatedAt
}

%%====================================================
%% ORDERS
%%====================================================

Orders {
    INT OrderID PK
    INT UserID FK
    INT BillingAddressID FK
    INT ShippingAddressID FK
    INT PaymentID FK
    INT OrderStatusID FK
    NVARCHAR OrderNumber
    DECIMAL Subtotal
    DECIMAL ShippingFee
    DECIMAL Discount
    DECIMAL Tax
    DECIMAL Total
    NVARCHAR Currency
    NVARCHAR Notes
    DATETIME OrderedAt
    DATETIME UpdatedAt
}

OrderItems {
    INT OrderItemID PK
    INT OrderID FK
    INT ProductID FK
    INT ProductVariantID FK
    INT VendorProfileID FK
    DECIMAL Quantity
    DECIMAL UnitPrice
    DECIMAL Discount
    DECIMAL Tax
    DECIMAL Total
}

%%====================================================
%% ORDER STATUS
%%====================================================

OrderStatus {
    INT OrderStatusID PK
    NVARCHAR Name
    NVARCHAR Code
    INT DisplayOrder
}

%%====================================================
%% PAYMENTS
%%====================================================

Payments {
    INT PaymentID PK
    INT OrderID FK
    INT PaymentMethodID FK
    DECIMAL Amount
    NVARCHAR Currency
    NVARCHAR TransactionID
    NVARCHAR ProviderReference
    TINYINT Status
    DATETIME PaidAt
    DATETIME CreatedAt
}

%%====================================================
%% CATEGORIES
%%====================================================

Categories {
    INT CategoryID PK
    INT ParentCategoryID FK
    NVARCHAR Name
    NVARCHAR Slug
    NVARCHAR IconURL
    BIT IsActive
    INT DisplayOrder
    DATETIME CreatedAt
    DATETIME UpdatedAt
}

CategoryClosure {
    INT AncestorID FK
    INT DescendantID FK
    INT Depth
}

ProductsConfigAttribute {
    INT AttributeID FK
    INT UnitID FK
    INT DisplayOrder
}
Units {
    INT UnitID PK
    NVARCHAR Name
    NVARCHAR Symbol
    INT DisplayOrder
    BIT IsActive
}

ConfigAttributeOptions {
    INT OptionID PK
    INT ProductsConfigAttributeID FK
    NVARCHAR OptionLabel
    NVARCHAR OptionValue
    INT DisplayOrder
    BIT IsDefaultForAttribute
}

%%====================================================
%% BRANDS / MODELS
%%====================================================

Brands {
    INT BrandID PK
    NVARCHAR Name
    NVARCHAR Slug
    NVARCHAR LogoURL
    NVARCHAR Website
    NVARCHAR Description
    INT CountryID
    BIT IsActive
    DATETIME CreatedAt
    DATETIME UpdatedAt
}

Models {
    INT ModelID PK
    INT BrandID FK
    NVARCHAR Name
    NVARCHAR Code
    NVARCHAR Description
    SMALLINT ReleaseYear
    BIT IsActive
    DATETIME CreatedAt
    DATETIME UpdatedAt
}

%%====================================================
%% PRODUCTS
%%====================================================

Products {
    INT ProductID PK
    INT VendorID FK
    INT BrandID FK "Allow Null"
    INT ModelID FK "Allow Null"
    NVARCHAR Name
    NVARCHAR Barcode
    NVARCHAR Description
    DECIMAL BasePrice
    INT Stock
    TINYINT Status "draft,validated,Accepted,blocked"
    DATETIME CreatedAt
    DATETIME UpdatedAt
    DATETIME DeletedAt "Null"
    bool IsActive "false"
    string RefuseNotes
    INT RefusedBy FK
    DATETIME RefuseAt
    INT RefuseAtempt "default : 1,max : 3"
    INT ValidatorID FK
    String ValidationNotes
    DATETIME ValidationDate
    bool IsBlocked
    INT BlokedBy FK
    DATETIME BlockedDate
    String BlockedNotes
}
ProductResources {
    INT ID
    INT ProductID FK
    String ResourcesPath
    INT ResourcesTypeID FK
    ID ResourceRoleID Fk
}
ResourcesRoles{
    int RoleID
    string label "Validation ,Cover , Descriptions"
}
ResourcesTypes {
    INT ID
    String Name "audio , Video ,Png , etc"
}
ProductAllowedPayements {
   INT ID
   INT ProductID FK
   INT PayementMethodID FK

}

ProductDetails {
    INT ProductDetailID PK
    INT ProductID FK
    INT ProductsConfigAttributeID FK
    INT OptionID FK
    NVARCHAR CustomValue
   
}

%%====================================================
%% PRODUCT CATEGORIES
%%====================================================

ProductCategories {
    INT ProductID PK,FK
    INT CategoryID PK,FK
    BIT IsPrimary
}

%%====================================================
%% PRODUCT TAGS
%%====================================================

Tags {
    INT TagID PK
    NVARCHAR Name
    NVARCHAR Color
    NVARCHAR Description
    BIT IsActive
    DATETIME CreatedAt
}

ProductTags {
    INT ProductID PK,FK
    INT TagID PK,FK
    DATETIME CreatedAt
}

%%====================================================
%% SEARCH
%%====================================================

ProductSearchIndex {
    INT ProductID PK,FK
    NVARCHAR SearchText
    NVARCHAR CategoryPath
    DATETIME LastIndexed
}
SearchDictionary {
        INT SearchTermID PK
        NVARCHAR DisplayText
        NVARCHAR NormalizedText

        TINYINT SourceType
        INT SourceID

        DECIMAL Score
        INT SearchHitCount
        INT SearchHitCount7d
        INT ResultCount

        DATETIME LastSearchedAt
        BIT IsActive
        DATETIME CreatedAt
        DATETIME UpdatedAt
    }

UserSearchHistory {
        INT UserSearchID PK

        INT UserID FK
        NVARCHAR SessionID

        NVARCHAR SearchText
        NVARCHAR NormalizedText

        INT ResultCount
        INT ClickedProductID FK

        VARCHAR IPAddress
        INT IPGeoLocationID FK
        DATETIME SearchedAt
    }

SearchSynonyms {
        INT SynonymID PK

        NVARCHAR Term
        NVARCHAR NormalizedTerm

        INT MapsToSearchTermID FK

        NVARCHAR LanguageCode
        BIT IsActive
        DATETIME CreatedAt
    }
SearchTermProductStats {
        INT SearchTermProductID PK

        INT SearchTermID FK
        INT ProductID FK

        INT ImpressionCount
        INT ClickCount
        INT PurchaseCount

        DECIMAL ClickThroughRate
        DECIMAL ConversionRate

        DATETIME LastInteractionAt
        DATETIME CreatedAt
        DATETIME UpdatedAt
    }
UserRefreshTokens {
    INT UserRefreshTokenID PK
    INT UserID FK
    NVARCHAR Token
    NVARCHAR TokenHash        "store hash, not raw token"
    NVARCHAR DeviceInfo
    NVARCHAR IPAddress
    DATETIME ExpiresAt
    BIT IsRevoked
    DATETIME RevokedAt
    NVARCHAR ReplacedByToken  "for rotation chain tracking"
    DATETIME CreatedAt
}
ProductRankingFactors {
        INT ProductRankingFactorID PK

        INT ProductID FK

        INT SalesCount30d
        INT ViewCount30d

        BIT InStock
        INT StockLevel

        BIT IsFeatured
        DECIMAL FreshnessScore

        DECIMAL FinalRankingScore

        DATETIME LastCalculatedAt
    }
RegionalProductStats {
        INT RegionalProductStatID PK

        CHAR CountryCode
        NVARCHAR Region
        INT ProductID FK

        INT ViewCount
        INT PurchaseCount

        DECIMAL TrendScore

        DATETIME LastUpdatedAt
    }
IPGeoLocations {
        INT IPGeoLocationID PK

        VARCHAR IPAddress
        CHAR CountryCode
        NVARCHAR Region
        NVARCHAR City

        DECIMAL Latitude
        DECIMAL Longitude

        DATETIME ResolvedAt
        DATETIME ExpiresAt
    }

%% ========================================
%% DIMENSIONS
%% ========================================

DIM_TYPE_EVENEMENT {
    INT id_type_evenement PK
    VARCHAR code UK
    VARCHAR nom
    INT points
    BOOLEAN est_actif
}

%% ========================================
%% TABLE DE FAITS
%% ========================================

FAIT_EVENEMENT_CLIENT {
    INT id_evenement PK
    INT id_utilisateur FK
    INT id_annonce FK
    INT id_type_evenement FK
    INT score
    DATETIME date_evenement
}

FAIT_SCORE_CLIENT_PRODUIT {
    INT id PK
    INT id_utilisateur FK
    INT id_annonce FK
    INT score_total
    DATETIME derniere_mise_a_jour
}

%% ========================================
%% RELATIONS
%% ========================================

Users ||--o{ FAIT_EVENEMENT_CLIENT : "génère"
Products ||--o{ FAIT_EVENEMENT_CLIENT : "concerne"
DIM_TYPE_EVENEMENT ||--o{ FAIT_EVENEMENT_CLIENT : "type"

Users ||--o{ FAIT_SCORE_CLIENT_PRODUIT : "score"
Products ||--o{ FAIT_SCORE_CLIENT_PRODUIT : "score"









%%====================================================
%% CATEGORY HIERARCHY
%%====================================================

Categories ||--o{ Categories : "Parent -> Child"

Categories ||--o{ CategoryClosure : Ancestor
Categories ||--o{ CategoryClosure : Descendant

%%====================================================
%% CATEGORY ATTRIBUTES
%%====================================================
UserDevices ||--o{ UserRefreshTokens : issues
Users ||--o{ UserRefreshTokens : owns
Categories ||--o{ ProductsConfigAttribute : defines

Units ||--o{ ProductsConfigAttribute : uses_unit

ProductsConfigAttribute ||--o{ ConfigAttributeOptions : has_options

%%====================================================
%% BRANDS / MODELS
%%====================================================

Countries ||--o{ Brands : origin_country

Brands ||--o{ Models : owns

Brands ||--o{ Products : manufacturer

Models ||--o{ Products : model

%%====================================================
%% PRODUCTS
%%====================================================

Users ||--o{ Products : owns

Users ||--o{ Products : validated_by

Users ||--o{ Products : refused_by

Users ||--o{ Products : blocked_by

%%====================================================
%% PRODUCT CATEGORIES
%%====================================================

Products ||--o{ ProductCategories : belongs_to

Categories ||--o{ ProductCategories : contains

%%====================================================
%% PRODUCT DETAILS
%%====================================================

Products ||--o{ ProductDetails : has

ProductsConfigAttribute ||--o{ ProductDetails : attribute

ConfigAttributeOptions ||--o{ ProductDetails : selected_option

%%====================================================
%% PRODUCT RESOURCES
%%====================================================

Products ||--o{ ProductResources : has

ResourcesTypes ||--o{ ProductResources : type

ResourcesRoles ||--o{ ProductResources : role

%%====================================================
%% TAGS
%%====================================================

Products ||--o{ ProductTags : tagged

Tags ||--o{ ProductTags : tag

%%====================================================
%% SEARCH
%%====================================================

Products ||--|| ProductSearchIndex : indexed

%%====================================================
%% PRODUCT ALLOWED PAYMENTS
%%====================================================

Products ||--o{ ProductAllowedPayements : allows

PaymentMethods ||--o{ ProductAllowedPayements : used_in
%%====================================================
    %% RELATIONSHIPS
    %%====================================================

    Products ||--|| ProductRankingFactors : ranking_factors
    SearchDictionary ||--o{ SearchTermProductStats : tracks
    Products ||--o{ SearchTermProductStats : statistics
    %%====================================================
    %% RELATIONSHIPS
    %%====================================================

    Users ||--o{ UserSearchHistory : performs

    Products ||--o{ UserSearchHistory : clicked

    SearchDictionary ||--o{ SearchSynonyms : canonical_term

    %% Logical relationship (not enforced by FK)
    SearchDictionary ||..o{ UserSearchHistory : matches_NormalizedText
       Products ||--o{ RegionalProductStats : regional_statistics

    IPGeoLocations ||--o{ UserSearchHistory : resolved_location
  Users ||--o{ UserExternalLogins : "has"
OrderItems ||--o| Products : refer
WishListItems ||--o| Products : refer
CartItems ||--o| Products : refer
Users ||--o{ UserRoles : has
Roles ||--o{ UserRoles : assigned
Users ||--o| VendorProfiles : vendor
Users ||--o| CustomerProfiles : customer
Users ||--o| AdminProfiles : admin

Users ||--o{ Addresses : has
Users ||--o{ PaymentInformations : owns
Users ||--o{ WishLists : owns
Users ||--|| Carts : owns
Users ||--o{ Orders : places

WishLists ||--o{ WishListItems : contains
Carts ||--o{ CartItems : contains

Orders ||--|{ OrderItems : contains
Orders }o--|| Payments : payment
Orders }o--|| OrderStatus : status

VendorProfiles ||--o{ BankAccounts : owns
VendorProfiles ||--o{ OrderItems : sells

BankAccounts ||--o{ WithdrawHistory : withdrawals

PaymentMethods ||--o{ Payments : used_by
PaymentMethods ||--o{ WithdrawHistory : withdraw_by
PaymentMethods ||--o{ PaymentInformations : account

Addresses ||--o{ Orders : billing
Addresses ||--o{ Orders : shipping
 Users ||--o{ Notifications : receives
    NotificationTypes ||--o{ Notifications : type

    Users ||--o{ UserDevices : owns

    Users ||--o{ UserNotificationPreferences : configures
    NotificationTypes ||--o{ UserNotificationPreferences : preference

    Notifications ||--o{ NotificationDeliveryLog : delivery
    UserDevices ||--o{ NotificationDeliveryLog : sent_to
```