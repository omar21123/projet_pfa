-- =============================================================================
-- MARKETPLACE PLATFORM — MySQL 8.0 SCHEMA INIT SCRIPT
-- Designed to run automatically via Docker's official mysql image:
--   mount this file at /docker-entrypoint-initdb.d/init.sql
--   -> it only runs ONCE, the first time the container starts with an
--      empty data directory (empty volume). If you need to re-run it,
--      you must first blow away the mysql data volume.
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS marketplace_db
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE marketplace_db;

-- =============================================================================
-- LOOKUP / REFERENCE TABLES (no FK dependencies)
-- =============================================================================

CREATE TABLE Countries (
    CountryID   INT AUTO_INCREMENT PRIMARY KEY,
    Code        CHAR(2) NOT NULL,
    Name        VARCHAR(100) NOT NULL,
    UNIQUE KEY UX_Countries_Code (Code)
) ENGINE=InnoDB;

CREATE TABLE Roles (
    RoleID      INT AUTO_INCREMENT PRIMARY KEY,
    Name        VARCHAR(100) NOT NULL,
    Code        VARCHAR(50) NOT NULL,
    Description VARCHAR(255),
    IsSystem    TINYINT(1) NOT NULL DEFAULT 0,
    CreatedAt   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY UX_Roles_Code (Code)
) ENGINE=InnoDB;

CREATE TABLE PaymentMethods (
    PaymentMethodID INT AUTO_INCREMENT PRIMARY KEY,
    Name            VARCHAR(100) NOT NULL,
    Code            VARCHAR(50) NOT NULL,
    IconURL         VARCHAR(500),
    WithdrawTax     DECIMAL(12,2) NOT NULL DEFAULT 0,
    IsOnline        TINYINT(1) NOT NULL DEFAULT 0,
    IsActive        TINYINT(1) NOT NULL DEFAULT 1,
    DisplayOrder    INT NOT NULL DEFAULT 0,
    UNIQUE KEY UX_PaymentMethods_Code (Code),
    KEY IXF_PaymentMethods_Active (DisplayOrder)
) ENGINE=InnoDB;

CREATE TABLE OrderStatus (
    OrderStatusID INT AUTO_INCREMENT PRIMARY KEY,
    Name          VARCHAR(100) NOT NULL,
    Code          VARCHAR(50) NOT NULL,
    DisplayOrder  INT NOT NULL DEFAULT 0,
    UNIQUE KEY UX_OrderStatus_Code (Code)
) ENGINE=InnoDB;

CREATE TABLE NotificationTypes (
    NotificationTypeID  INT AUTO_INCREMENT PRIMARY KEY,
    Code                VARCHAR(50) NOT NULL,
    Category            TINYINT NOT NULL,
    TitleTemplate       VARCHAR(255) NOT NULL,
    BodyTemplate        VARCHAR(500) NOT NULL,
    DefaultPushEnabled  TINYINT(1) NOT NULL DEFAULT 1,
    IsUserConfigurable  TINYINT(1) NOT NULL DEFAULT 1,
    IsActive            TINYINT(1) NOT NULL DEFAULT 1,
    CreatedAt           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY UX_NotificationTypes_Code (Code),
    KEY IXF_NotificationTypes_Active (Category)
) ENGINE=InnoDB;

CREATE TABLE Units (
    UnitID       INT AUTO_INCREMENT PRIMARY KEY,
    Name         VARCHAR(100) NOT NULL,
    Symbol       VARCHAR(20) NOT NULL,
    DisplayOrder INT NOT NULL DEFAULT 0,
    IsActive     TINYINT(1) NOT NULL DEFAULT 1,
    KEY IXF_Units_Active_Order (DisplayOrder)
) ENGINE=InnoDB;

CREATE TABLE ResourcesTypes (
    ID   INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    UNIQUE KEY UX_ResourcesTypes_Name (Name)
) ENGINE=InnoDB;

CREATE TABLE ResourcesRoles (
    RoleID INT AUTO_INCREMENT PRIMARY KEY,
    Label  VARCHAR(50) NOT NULL,
    UNIQUE KEY UX_ResourcesRoles_Label (Label)
) ENGINE=InnoDB;

CREATE TABLE Tags (
    TagID       INT AUTO_INCREMENT PRIMARY KEY,
    Name        VARCHAR(100) NOT NULL,
    Color       VARCHAR(20),
    Description VARCHAR(255),
    IsActive    TINYINT(1) NOT NULL DEFAULT 1,
    CreatedAt   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY UX_Tags_Name (Name)
) ENGINE=InnoDB;

CREATE TABLE DIM_TYPE_EVENEMENT (
    id_type_evenement INT AUTO_INCREMENT PRIMARY KEY,
    code              VARCHAR(50) NOT NULL,
    nom               VARCHAR(100) NOT NULL,
    points            INT NOT NULL DEFAULT 0,
    est_actif         TINYINT(1) NOT NULL DEFAULT 1,
    UNIQUE KEY UX_DIM_TYPE_EVENEMENT_code (code)
) ENGINE=InnoDB;


-- =============================================================================
-- IDENTITY & ACCESS
-- =============================================================================

CREATE TABLE Users (
    UserID        INT AUTO_INCREMENT PRIMARY KEY,
    PublicID      CHAR(36) NOT NULL DEFAULT (UUID()),
    FirstName     VARCHAR(100),
    LastName      VARCHAR(100),
    DisplayName   VARCHAR(150),
    BirthDate     DATE,
    Gender        TINYINT,
    Email         VARCHAR(255) NOT NULL,
    PhoneNumber   VARCHAR(20),
    PasswordHash  VARCHAR(255),
    AvatarURL     VARCHAR(500),
    HasPassword   TINYINT(1) NOT NULL DEFAULT 1,
    EmailVerified TINYINT(1) NOT NULL DEFAULT 0,
    PhoneVerified TINYINT(1) NOT NULL DEFAULT 0,
    IsActive      TINYINT(1) NOT NULL DEFAULT 1,
    IsDeleted     TINYINT(1) NOT NULL DEFAULT 0,
    LastLoginAt   DATETIME,
    CreatedAt     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY UX_Users_PublicID (PublicID),
    UNIQUE KEY UX_Users_Email (Email),
    UNIQUE KEY UX_Users_PhoneNumber (PhoneNumber),
    KEY IXC_Users_Email_Login (Email, PasswordHash(1), IsActive, EmailVerified, HasPassword),
    KEY IXF_Users_Active_CreatedAt (IsActive, IsDeleted, CreatedAt),
    KEY IXF_Users_LastLoginAt (LastLoginAt)
) ENGINE=InnoDB;

CREATE TABLE UserExternalLogins (
    UserExternalLoginID  INT AUTO_INCREMENT PRIMARY KEY,
    UserID               INT NOT NULL,
    Provider             TINYINT NOT NULL,
    ProviderUserID       VARCHAR(255) NOT NULL,
    Email                VARCHAR(255),
    IsEmailPrivateRelay  TINYINT(1) NOT NULL DEFAULT 0,
    DisplayName          VARCHAR(150),
    AvatarURL            VARCHAR(500),
    RefreshToken         VARCHAR(500),
    AccessTokenExpiresAt DATETIME,
    IsVerifiedEmail      TINYINT(1) NOT NULL DEFAULT 0,
    LinkedAt             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastLoginAt          DATETIME,
    RevokedAt            DATETIME,
    CONSTRAINT FK_UserExternalLogins_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_UserExternalLogins_Provider (Provider, ProviderUserID),
    KEY IX_UserExternalLogins_UserID (UserID),
    KEY IX_UserExternalLogins_Email (Email)
) ENGINE=InnoDB;

CREATE TABLE UserRoles (
    UserRoleID INT AUTO_INCREMENT PRIMARY KEY,
    UserID     INT NOT NULL,
    RoleID     INT NOT NULL,
    AssignedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    AssignedBy INT,
    CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleID) REFERENCES Roles(RoleID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_UserRoles_AssignedBy FOREIGN KEY (AssignedBy) REFERENCES Users(UserID) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE KEY UX_UserRoles_User_Role (UserID, RoleID),
    KEY IX_UserRoles_RoleID (RoleID)
) ENGINE=InnoDB;

CREATE TABLE VendorProfiles (
    VendorProfileID    INT AUTO_INCREMENT PRIMARY KEY,
    UserID             INT NOT NULL,
    StoreName          VARCHAR(150) NOT NULL,
    Description        TEXT,
    LogoURL            VARCHAR(500),
    BannerURL          VARCHAR(500),
    Rating             DECIMAL(3,2) NOT NULL DEFAULT 0,
    ReviewCount        INT NOT NULL DEFAULT 0,
    IdentityVerified   TINYINT(1) NOT NULL DEFAULT 0,
    BusinessVerified   TINYINT(1) NOT NULL DEFAULT 0,
    BankVerified       TINYINT(1) NOT NULL DEFAULT 0,
    VerificationStatus TINYINT NOT NULL DEFAULT 0,
    IsApproved         TINYINT(1) NOT NULL DEFAULT 0,
    IsSuspended        TINYINT(1) NOT NULL DEFAULT 0,
    SuspendedAt        DATETIME,
    ApprovedAt         DATETIME,
    CreatedAt          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    VerifiedBy INT NULL,
    VerificationNotes NVARCHAR(500) NULL,
    RejectionNotes NVARCHAR(500) NULL,
    SuspendedBy INT NULL,
    SuspensionNotes NVARCHAR(500) NULL,
    CONSTRAINT FK_VendorProfiles_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_VendorProfiles_UserID (UserID),
    KEY IXF_VendorProfiles_Approved (IsApproved, IsSuspended),
    KEY IX_VendorProfiles_StoreName (StoreName),
    KEY IX_VendorProfiles_Rating (Rating)
) ENGINE=InnoDB;

CREATE TABLE AdminProfiles (
    AdminProfileID INT AUTO_INCREMENT PRIMARY KEY,
    UserID         INT NOT NULL,
    EmployeeNumber VARCHAR(50) NOT NULL,
    CIN            VARCHAR(50) NOT NULL,
    Position       VARCHAR(100),
    Status         TINYINT NOT NULL DEFAULT 1,
    IdentityVerified TINYINT(1) NOT NULL DEFAULT 0,
    HireDate       DATE,
    CreatedAt      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT FK_AdminProfiles_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_AdminProfiles_UserID (UserID),
    UNIQUE KEY UX_AdminProfiles_EmployeeNumber (EmployeeNumber),
    UNIQUE KEY UX_AdminProfiles_CIN (CIN)
) ENGINE=InnoDB;

CREATE TABLE CustomerProfiles (
    CustomerProfileID     INT AUTO_INCREMENT PRIMARY KEY,
    UserID                INT NOT NULL,
    LoyaltyPoints         INT NOT NULL DEFAULT 0,
    AcceptMarketingEmails TINYINT(1) NOT NULL DEFAULT 0,
    CreatedAt             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT FK_CustomerProfiles_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_CustomerProfiles_UserID (UserID)
) ENGINE=InnoDB;


-- =============================================================================
-- ADDRESSES
-- =============================================================================

CREATE TABLE Addresses (
    AddressID         INT AUTO_INCREMENT PRIMARY KEY,
    UserID            INT NOT NULL,
    FullName          VARCHAR(150) NOT NULL,
    Phone             VARCHAR(20),
    Country           VARCHAR(100) NOT NULL,
    Region            VARCHAR(100),
    City              VARCHAR(100) NOT NULL,
    PostalCode        VARCHAR(20),
    AddressLine1      VARCHAR(255) NOT NULL,
    AddressLine2      VARCHAR(255),
    Landmark          VARCHAR(255),
    Latitude          DECIMAL(10,7),
    Longitude         DECIMAL(10,7),
    IsDefaultBilling  TINYINT(1) NOT NULL DEFAULT 0,
    IsDefaultShipping TINYINT(1) NOT NULL DEFAULT 0,
    CreatedAt         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Addresses_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    KEY IX_Addresses_UserID (UserID),
    KEY IXF_Addresses_DefaultShipping (UserID, IsDefaultShipping),
    KEY IXF_Addresses_DefaultBilling (UserID, IsDefaultBilling),
    KEY IX_Addresses_City_Region (Country, Region, City)
) ENGINE=InnoDB;


-- =============================================================================
-- VENDOR FINANCE
-- =============================================================================

CREATE TABLE PaymentInformations (
    PaymentInformationID INT AUTO_INCREMENT PRIMARY KEY,
    UserID          INT NOT NULL,
    PaymentMethodID INT NOT NULL,
    AccountName     VARCHAR(150),
    AccountNumber   VARCHAR(100),
    IBAN            VARCHAR(50),
    SwiftCode       VARCHAR(20),
    PaypalEmail     VARCHAR(255),
    WalletAddress   VARCHAR(255),
    IsDefault       TINYINT(1) NOT NULL DEFAULT 0,
    IsVerified      TINYINT(1) NOT NULL DEFAULT 0,
    CreatedAt       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_PaymentInformations_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_PaymentInformations_Method FOREIGN KEY (PaymentMethodID) REFERENCES PaymentMethods(PaymentMethodID) ON DELETE RESTRICT ON UPDATE CASCADE,
    KEY IX_PaymentInformations_UserID (UserID),
    KEY IX_PaymentInformations_PaymentMethodID (PaymentMethodID),
    KEY IXF_PaymentInformations_Default (UserID, IsDefault)
) ENGINE=InnoDB;

CREATE TABLE BankAccounts (
    BankAccountID       INT AUTO_INCREMENT PRIMARY KEY,
    VendorProfileID     INT NOT NULL,
    CurrentBalance      DECIMAL(14,2) NOT NULL DEFAULT 0,
    WithdrawableBalance DECIMAL(14,2) NOT NULL DEFAULT 0,
    PendingBalance      DECIMAL(14,2) NOT NULL DEFAULT 0,
    CurrencyCode        CHAR(3) NOT NULL DEFAULT 'MAD',
    IsLocked            TINYINT(1) NOT NULL DEFAULT 0,
    CreatedAt           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT FK_BankAccounts_Vendor FOREIGN KEY (VendorProfileID) REFERENCES VendorProfiles(VendorProfileID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_BankAccounts_VendorProfileID (VendorProfileID)
) ENGINE=InnoDB;

CREATE TABLE WithdrawHistory (
    WithdrawID        INT AUTO_INCREMENT PRIMARY KEY,
    BankAccountID     INT NOT NULL,
    PaymentMethodID   INT NOT NULL,
    Amount            DECIMAL(14,2) NOT NULL,
    ExternalReference VARCHAR(150),
    Status            TINYINT NOT NULL DEFAULT 0,
    Notes             VARCHAR(500),
    RequestedAt       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ProcessedAt       DATETIME,
    CONSTRAINT FK_WithdrawHistory_Bank FOREIGN KEY (BankAccountID) REFERENCES BankAccounts(BankAccountID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_WithdrawHistory_Method FOREIGN KEY (PaymentMethodID) REFERENCES PaymentMethods(PaymentMethodID) ON DELETE RESTRICT ON UPDATE CASCADE,
    KEY IX_WithdrawHistory_BankAccountID (BankAccountID, RequestedAt),
    KEY IX_WithdrawHistory_PaymentMethodID (PaymentMethodID),
    KEY IXF_WithdrawHistory_Status (Status, RequestedAt)
) ENGINE=InnoDB;


-- =============================================================================
-- CATALOG: CATEGORIES, ATTRIBUTES, BRANDS
-- =============================================================================

CREATE TABLE Categories (
    CategoryID       INT AUTO_INCREMENT PRIMARY KEY,
    ParentCategoryID INT,
    Name             VARCHAR(150) NOT NULL,
    Slug             VARCHAR(150) NOT NULL,
    IconURL          VARCHAR(500),
    IsActive         TINYINT(1) NOT NULL DEFAULT 1,
    DisplayOrder     INT NOT NULL DEFAULT 0,
    CreatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT FK_Categories_Parent FOREIGN KEY (ParentCategoryID) REFERENCES Categories(CategoryID) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE KEY UX_Categories_Slug (Slug),
    KEY IX_Categories_ParentCategoryID (ParentCategoryID),
    KEY IXF_Categories_Active_Order (IsActive, DisplayOrder)
) ENGINE=InnoDB;

CREATE TABLE CategoryClosure (
    AncestorID   INT NOT NULL,
    DescendantID INT NOT NULL,
    Depth        INT NOT NULL,
    PRIMARY KEY (AncestorID, DescendantID),
    CONSTRAINT FK_CategoryClosure_Ancestor FOREIGN KEY (AncestorID) REFERENCES Categories(CategoryID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_CategoryClosure_Descendant FOREIGN KEY (DescendantID) REFERENCES Categories(CategoryID) ON DELETE CASCADE ON UPDATE CASCADE,
    KEY IX_CategoryClosure_DescendantID (DescendantID, AncestorID),
    KEY IX_CategoryClosure_AncestorID (AncestorID, Depth)
) ENGINE=InnoDB;

CREATE TABLE Brands (
    BrandID     INT AUTO_INCREMENT PRIMARY KEY,
    Name        VARCHAR(150) NOT NULL,
    Slug        VARCHAR(150) NOT NULL,
    LogoURL     VARCHAR(500),
    Website     VARCHAR(255),
    Description TEXT,
    CountryID   INT,
    IsActive    TINYINT(1) NOT NULL DEFAULT 1,
    CreatedAt   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT FK_Brands_Countries FOREIGN KEY (CountryID) REFERENCES Countries(CountryID) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE KEY UX_Brands_Slug (Slug),
    KEY IX_Brands_CountryID (CountryID),
    KEY IXF_Brands_Active_Name (IsActive, Name)
) ENGINE=InnoDB;

CREATE TABLE Models (
    ModelID     INT AUTO_INCREMENT PRIMARY KEY,
    BrandID     INT NOT NULL,
    Name        VARCHAR(150) NOT NULL,
    Code        VARCHAR(50),
    Description TEXT,
    ReleaseYear SMALLINT,
    IsActive    TINYINT(1) NOT NULL DEFAULT 1,
    CreatedAt   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT FK_Models_Brands FOREIGN KEY (BrandID) REFERENCES Brands(BrandID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_Models_Brand_Code (BrandID, Code),
    KEY IX_Models_BrandID (BrandID)
) ENGINE=InnoDB;

CREATE TABLE ProductsConfigAttribute (
    AttributeID  INT AUTO_INCREMENT PRIMARY KEY,
    UnitID       INT,
    IsActive TINYINT(1) NOT NULL DEFAULT 1,
    Name         VARCHAR(150) NOT NULL,
    DisplayOrder INT NOT NULL DEFAULT 0,
     CreatedAt DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
     UpdatedAt DATETIME NULL,
    CONSTRAINT FK_ProductsConfigAttribute_Unit FOREIGN KEY (UnitID) REFERENCES Units(UnitID) ON DELETE SET NULL ON UPDATE CASCADE,
    KEY IX_ProductsConfigAttribute_UnitID (UnitID)
    
) ENGINE=InnoDB;

ALTER TABLE ProductsConfigAttribute
    ADD UNIQUE KEY UQ_ProductsConfigAttribute_Name (Name);

CREATE TABLE ConfigAttributeOptions (
    OptionID                  INT AUTO_INCREMENT PRIMARY KEY,
    ProductsConfigAttributeID INT NOT NULL,
    OptionLabel               VARCHAR(150) NOT NULL,
    OptionValue               VARCHAR(150) NOT NULL,
    DisplayOrder              INT NOT NULL DEFAULT 0,
    IsDefaultForAttribute     TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT FK_ConfigAttributeOptions_Attribute FOREIGN KEY (ProductsConfigAttributeID) REFERENCES ProductsConfigAttribute(AttributeID) ON DELETE CASCADE ON UPDATE CASCADE,
    KEY IX_ConfigAttributeOptions_AttributeID (ProductsConfigAttributeID, DisplayOrder)
) ENGINE=InnoDB;
ALTER TABLE ConfigAttributeOptions
    ADD COLUMN IsActive TINYINT(1) NOT NULL DEFAULT 1,
    ADD COLUMN CreatedAt DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN UpdatedAt DATETIME NULL,
    ADD UNIQUE KEY UQ_ConfigAttributeOptions_Attr_Label (ProductsConfigAttributeID, OptionLabel);

-- =============================================================================
-- PRODUCTS
-- =============================================================================

CREATE TABLE Products (
    ProductID        INT AUTO_INCREMENT PRIMARY KEY,
    VendorID         INT NOT NULL,
    BrandID          INT,
    ModelID          INT,
    Name             VARCHAR(255) NOT NULL,
    Barcode          VARCHAR(100),
    Description      TEXT,
    BasePrice        DECIMAL(12,2) NOT NULL DEFAULT 0,
    Stock            INT NOT NULL DEFAULT 0,
    Status           TINYINT NOT NULL DEFAULT 0 COMMENT '0=draft,1=validated,2=accepted,3=blocked',
    CreatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    DeletedAt        DATETIME NULL,
    IsActive         TINYINT(1) NOT NULL DEFAULT 0,
    RefuseNotes      VARCHAR(500),
    RefusedBy        INT,
    RefuseAt         DATETIME,
    RefuseAttempt    INT NOT NULL DEFAULT 1,
    ValidatorID      INT,
    ValidationNotes  VARCHAR(500),
    ValidationDate   DATETIME,
    IsBlocked        TINYINT(1) NOT NULL DEFAULT 0,
    BlokedBy         INT,
    BlockedDate      DATETIME,
    BlockedNotes     VARCHAR(500),
    CONSTRAINT FK_Products_Vendor    FOREIGN KEY (VendorID)    REFERENCES Users(UserID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_Products_Brand     FOREIGN KEY (BrandID)     REFERENCES Brands(BrandID) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT FK_Products_Model     FOREIGN KEY (ModelID)     REFERENCES Models(ModelID) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT FK_Products_RefusedBy FOREIGN KEY (RefusedBy)   REFERENCES Users(UserID) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT FK_Products_Validator FOREIGN KEY (ValidatorID) REFERENCES Users(UserID) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT FK_Products_BlokedBy  FOREIGN KEY (BlokedBy)    REFERENCES Users(UserID) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE KEY UX_Products_Barcode (Barcode),
    KEY IX_Products_VendorID (VendorID),
    KEY IX_Products_BrandID (BrandID),
    KEY IX_Products_ModelID (ModelID),
    KEY IX_Products_ValidatorID (ValidatorID),
    KEY IX_Products_RefusedBy (RefusedBy),
    KEY IX_Products_BlokedBy (BlokedBy),
    KEY IXF_Products_Storefront (IsActive, IsBlocked, Status, CreatedAt),
    KEY IX_Products_Vendor_Status (VendorID, Status),
    KEY IXF_Products_PendingValidation (Status, CreatedAt)
) ENGINE=InnoDB;

CREATE TABLE ProductResources (
    ID              INT AUTO_INCREMENT PRIMARY KEY,
    ProductID       INT NOT NULL,
    ResourcesPath   VARCHAR(500) NOT NULL,
    ResourcesTypeID INT NOT NULL,
    ResourceRoleID  INT NOT NULL,
    CONSTRAINT FK_ProductResources_Product FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_ProductResources_Type    FOREIGN KEY (ResourcesTypeID) REFERENCES ResourcesTypes(ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_ProductResources_Role    FOREIGN KEY (ResourceRoleID) REFERENCES ResourcesRoles(RoleID) ON DELETE RESTRICT ON UPDATE CASCADE,
    KEY IX_ProductResources_ProductID (ProductID),
    KEY IX_ProductResources_ResourcesTypeID (ResourcesTypeID),
    KEY IXC_ProductResources_Product_Role (ProductID, ResourceRoleID, ResourcesPath(255))
) ENGINE=InnoDB;

CREATE TABLE ProductAllowedPayements (
    ID              INT AUTO_INCREMENT PRIMARY KEY,
    ProductID       INT NOT NULL,
    PayementMethodID INT NOT NULL,
    CONSTRAINT FK_ProductAllowedPayements_Product FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_ProductAllowedPayements_Method  FOREIGN KEY (PayementMethodID) REFERENCES PaymentMethods(PaymentMethodID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_ProductAllowedPayements_Prod_Method (ProductID, PayementMethodID),
    KEY IX_ProductAllowedPayements_PayementMethodID (PayementMethodID)
) ENGINE=InnoDB;

CREATE TABLE ProductDetails (
    ProductDetailID           INT AUTO_INCREMENT PRIMARY KEY,
    ProductID                 INT NOT NULL,
    ProductsConfigAttributeID INT NOT NULL,
    OptionID                  INT,
    CustomValue               VARCHAR(255),
    CONSTRAINT FK_ProductDetails_Product   FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_ProductDetails_Attribute FOREIGN KEY (ProductsConfigAttributeID) REFERENCES ProductsConfigAttribute(AttributeID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_ProductDetails_Option    FOREIGN KEY (OptionID) REFERENCES ConfigAttributeOptions(OptionID) ON DELETE SET NULL ON UPDATE CASCADE,
    KEY IX_ProductDetails_ProductID (ProductID),
    KEY IX_ProductDetails_AttributeID (ProductsConfigAttributeID),
    KEY IX_ProductDetails_OptionID (OptionID),
    KEY IX_ProductDetails_Attribute_Option (ProductsConfigAttributeID, OptionID, ProductID)
) ENGINE=InnoDB;

CREATE TABLE ProductCategories (
    ProductID  INT NOT NULL,
    CategoryID INT NOT NULL,
    IsPrimary  TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (ProductID, CategoryID),
    CONSTRAINT FK_ProductCategories_Product  FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_ProductCategories_Category FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID) ON DELETE CASCADE ON UPDATE CASCADE,
    KEY IX_ProductCategories_CategoryID (CategoryID, ProductID),
    KEY IXF_ProductCategories_Primary (ProductID, IsPrimary)
) ENGINE=InnoDB;

CREATE TABLE ProductTags (
    ProductID INT NOT NULL,
    TagID     INT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ProductID, TagID),
    CONSTRAINT FK_ProductTags_Product FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_ProductTags_Tag     FOREIGN KEY (TagID) REFERENCES Tags(TagID) ON DELETE CASCADE ON UPDATE CASCADE,
    KEY IX_ProductTags_TagID (TagID, ProductID)
) ENGINE=InnoDB;


-- =============================================================================
-- SEARCH & RANKING
-- =============================================================================

CREATE TABLE ProductSearchIndex (
    ProductID    INT NOT NULL PRIMARY KEY,
    SearchText   TEXT NOT NULL,
    CategoryPath VARCHAR(500),
    LastIndexed  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_ProductSearchIndex_Product FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    FULLTEXT KEY FTX_ProductSearchIndex_SearchText (SearchText)
) ENGINE=InnoDB;

CREATE TABLE SearchDictionary (
    SearchTermID     INT AUTO_INCREMENT PRIMARY KEY,
    DisplayText      VARCHAR(255) NOT NULL,
    NormalizedText   VARCHAR(255) NOT NULL,
    SourceType       TINYINT NOT NULL,
    SourceID         INT,
    Score            DECIMAL(10,4) NOT NULL DEFAULT 0,
    SearchHitCount   INT NOT NULL DEFAULT 0,
    SearchHitCount7d INT NOT NULL DEFAULT 0,
    ResultCount      INT NOT NULL DEFAULT 0,
    LastSearchedAt   DATETIME,
    IsActive         TINYINT(1) NOT NULL DEFAULT 1,
    CreatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY UX_SearchDictionary_NormalizedText (NormalizedText),
    KEY IXF_SearchDictionary_TopTerms (IsActive, Score, SearchHitCount7d),
    KEY IX_SearchDictionary_DisplayText (DisplayText),
    KEY IX_SearchDictionary_SourceType_SourceID (SourceType, SourceID)
) ENGINE=InnoDB;
CREATE TABLE UserRefreshTokens (
    UserRefreshTokenID   INT AUTO_INCREMENT PRIMARY KEY,
    UserID                INT NOT NULL,
    UserDeviceID           INT NULL,

    TokenHash             VARCHAR(255) NOT NULL,
    IPAddress               VARCHAR(45) NULL,

    ExpiresAt               DATETIME NOT NULL,
    IsRevoked                BOOLEAN NOT NULL DEFAULT FALSE,
    RevokedAt                DATETIME NULL,

    ReplacedByTokenHash  VARCHAR(255) NULL,

    CreatedAt               DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),

    CONSTRAINT FK_UserRefreshTokens_Users
        FOREIGN KEY (UserID) REFERENCES Users(UserID)
        ON DELETE CASCADE,

    CONSTRAINT FK_UserRefreshTokens_UserDevices
        FOREIGN KEY (UserDeviceID) REFERENCES UserDevices(UserDeviceID)
        ON DELETE CASCADE,

    INDEX IX_UserRefreshTokens_UserID (UserID),
    INDEX IX_UserRefreshTokens_UserDeviceID (UserDeviceID),
    INDEX IX_UserRefreshTokens_TokenHash (TokenHash),
    INDEX IX_UserRefreshTokens_ExpiresAt (ExpiresAt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IPGeoLocations (
    IPGeoLocationID INT AUTO_INCREMENT PRIMARY KEY,
    IPAddress       VARCHAR(45) NOT NULL,
    CountryCode     CHAR(2),
    Region          VARCHAR(100),
    City            VARCHAR(100),
    Latitude        DECIMAL(10,7),
    Longitude       DECIMAL(10,7),
    ResolvedAt      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ExpiresAt       DATETIME,
    UNIQUE KEY UX_IPGeoLocations_IPAddress (IPAddress),
    KEY IXF_IPGeoLocations_ExpiresAt (ExpiresAt)
) ENGINE=InnoDB;

CREATE TABLE UserSearchHistory (
    UserSearchID      INT AUTO_INCREMENT PRIMARY KEY,
    UserID            INT,
    SessionID         VARCHAR(100),
    SearchText        VARCHAR(255) NOT NULL,
    NormalizedText    VARCHAR(255) NOT NULL,
    ResultCount       INT NOT NULL DEFAULT 0,
    ClickedProductID  INT,
    IPAddress         VARCHAR(45),
    IPGeoLocationID   INT,
    SearchedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_UserSearchHistory_Users   FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT FK_UserSearchHistory_Product FOREIGN KEY (ClickedProductID) REFERENCES Products(ProductID) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT FK_UserSearchHistory_Geo     FOREIGN KEY (IPGeoLocationID) REFERENCES IPGeoLocations(IPGeoLocationID) ON DELETE SET NULL ON UPDATE CASCADE,
    KEY IX_UserSearchHistory_UserID (UserID, SearchedAt),
    KEY IX_UserSearchHistory_SessionID (SessionID),
    KEY IX_UserSearchHistory_NormalizedText (NormalizedText, SearchedAt),
    KEY IX_UserSearchHistory_ClickedProductID (ClickedProductID),
    KEY IX_UserSearchHistory_IPGeoLocationID (IPGeoLocationID)
) ENGINE=InnoDB;

CREATE TABLE SearchSynonyms (
    SynonymID           INT AUTO_INCREMENT PRIMARY KEY,
    Term                VARCHAR(255) NOT NULL,
    NormalizedTerm      VARCHAR(255) NOT NULL,
    MapsToSearchTermID  INT NOT NULL,
    LanguageCode        VARCHAR(10) NOT NULL DEFAULT 'fr',
    IsActive            TINYINT(1) NOT NULL DEFAULT 1,
    CreatedAt           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_SearchSynonyms_Term FOREIGN KEY (MapsToSearchTermID) REFERENCES SearchDictionary(SearchTermID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_SearchSynonyms_Term_Lang (NormalizedTerm, LanguageCode),
    KEY IX_SearchSynonyms_MapsToSearchTermID (MapsToSearchTermID)
) ENGINE=InnoDB;

CREATE TABLE SearchTermProductStats (
    SearchTermProductID INT AUTO_INCREMENT PRIMARY KEY,
    SearchTermID        INT NOT NULL,
    ProductID           INT NOT NULL,
    ImpressionCount     INT NOT NULL DEFAULT 0,
    ClickCount          INT NOT NULL DEFAULT 0,
    PurchaseCount       INT NOT NULL DEFAULT 0,
    ClickThroughRate    DECIMAL(8,5) NOT NULL DEFAULT 0,
    ConversionRate      DECIMAL(8,5) NOT NULL DEFAULT 0,
    LastInteractionAt   DATETIME,
    CreatedAt           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT FK_SearchTermProductStats_Term    FOREIGN KEY (SearchTermID) REFERENCES SearchDictionary(SearchTermID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_SearchTermProductStats_Product FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_SearchTermProductStats_Term_Product (SearchTermID, ProductID),
    KEY IX_SearchTermProductStats_ProductID (ProductID),
    KEY IXC_SearchTermProductStats_Ranking (SearchTermID, ConversionRate, ClickThroughRate, ProductID)
) ENGINE=InnoDB;

CREATE TABLE ProductRankingFactors (
    ProductRankingFactorID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID              INT NOT NULL,
    SalesCount30d          INT NOT NULL DEFAULT 0,
    ViewCount30d           INT NOT NULL DEFAULT 0,
    InStock                TINYINT(1) NOT NULL DEFAULT 1,
    StockLevel             INT NOT NULL DEFAULT 0,
    IsFeatured             TINYINT(1) NOT NULL DEFAULT 0,
    FreshnessScore         DECIMAL(8,4) NOT NULL DEFAULT 0,
    FinalRankingScore      DECIMAL(10,4) NOT NULL DEFAULT 0,
    LastCalculatedAt       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_ProductRankingFactors_Product FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_ProductRankingFactors_ProductID (ProductID),
    KEY IXF_ProductRankingFactors_Score (InStock, FinalRankingScore),
    KEY IXF_ProductRankingFactors_Featured (IsFeatured, InStock, FinalRankingScore)
) ENGINE=InnoDB;

CREATE TABLE RegionalProductStats (
    RegionalProductStatID INT AUTO_INCREMENT PRIMARY KEY,
    CountryCode           CHAR(2) NOT NULL,
    Region                VARCHAR(100),
    ProductID             INT NOT NULL,
    ViewCount             INT NOT NULL DEFAULT 0,
    PurchaseCount         INT NOT NULL DEFAULT 0,
    TrendScore            DECIMAL(10,4) NOT NULL DEFAULT 0,
    LastUpdatedAt         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_RegionalProductStats_Product FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_RegionalProductStats_Country_Product (CountryCode, Region, ProductID),
    KEY IX_RegionalProductStats_ProductID (ProductID),
    KEY IXC_RegionalProductStats_Trending (CountryCode, Region, TrendScore, ProductID)
) ENGINE=InnoDB;


-- =============================================================================
-- CART & WISHLIST
-- =============================================================================

CREATE TABLE Carts (
    CartID    INT AUTO_INCREMENT PRIMARY KEY,
    UserID    INT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT FK_Carts_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_Carts_UserID (UserID)
) ENGINE=InnoDB;

CREATE TABLE CartItems (
    CartItemID       INT AUTO_INCREMENT PRIMARY KEY,
    CartID           INT NOT NULL,
    ProductID        INT NOT NULL,
    ProductVariantID INT,
    Quantity         DECIMAL(10,2) NOT NULL DEFAULT 1,
    UnitPrice        DECIMAL(12,2) NOT NULL,
    CreatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_CartItems_Cart    FOREIGN KEY (CartID) REFERENCES Carts(CartID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_CartItems_Product FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_CartItems_Cart_Product_Variant (CartID, ProductID, ProductVariantID),
    KEY IX_CartItems_ProductID (ProductID),
    KEY IX_CartItems_ProductVariantID (ProductVariantID)
) ENGINE=InnoDB;

CREATE TABLE WishLists (
    WishListID INT AUTO_INCREMENT PRIMARY KEY,
    UserID     INT NOT NULL,
    Name       VARCHAR(150) NOT NULL DEFAULT 'My Wishlist',
    IsDefault  TINYINT(1) NOT NULL DEFAULT 1,
    CreatedAt  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_WishLists_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    KEY IX_WishLists_UserID (UserID),
    KEY IXF_WishLists_Default (UserID, IsDefault)
) ENGINE=InnoDB;

CREATE TABLE WishListItems (
    WishListItemID INT AUTO_INCREMENT PRIMARY KEY,
    WishListID     INT NOT NULL,
    ProductID      INT NOT NULL,
    CreatedAt      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_WishListItems_WishList FOREIGN KEY (WishListID) REFERENCES WishLists(WishListID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_WishListItems_Product  FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_WishListItems_List_Product (WishListID, ProductID),
    KEY IX_WishListItems_ProductID (ProductID)
) ENGINE=InnoDB;


-- =============================================================================
-- ORDERS & PAYMENTS
-- Orders <-> Payments is a circular reference (Orders.PaymentID -> Payments,
-- Payments.OrderID -> Orders), so Orders is created first WITHOUT the
-- PaymentID foreign key constraint, then the constraint is added after
-- Payments exists.
-- =============================================================================

CREATE TABLE Orders (
    OrderID           INT AUTO_INCREMENT PRIMARY KEY,
    UserID            INT NOT NULL,
    BillingAddressID  INT NOT NULL,
    ShippingAddressID INT NOT NULL,
    PaymentID         INT NULL,
    OrderStatusID     INT NOT NULL,
    OrderNumber       VARCHAR(50) NOT NULL,
    Subtotal          DECIMAL(12,2) NOT NULL DEFAULT 0,
    ShippingFee       DECIMAL(12,2) NOT NULL DEFAULT 0,
    Discount          DECIMAL(12,2) NOT NULL DEFAULT 0,
    Tax               DECIMAL(12,2) NOT NULL DEFAULT 0,
    Total             DECIMAL(12,2) NOT NULL DEFAULT 0,
    Currency          CHAR(3) NOT NULL DEFAULT 'MAD',
    Notes             VARCHAR(500),
    OrderedAt         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT FK_Orders_Users            FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_Orders_BillingAddress   FOREIGN KEY (BillingAddressID) REFERENCES Addresses(AddressID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_Orders_ShippingAddress  FOREIGN KEY (ShippingAddressID) REFERENCES Addresses(AddressID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_Orders_OrderStatus      FOREIGN KEY (OrderStatusID) REFERENCES OrderStatus(OrderStatusID) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY UX_Orders_OrderNumber (OrderNumber),
    KEY IX_Orders_UserID (UserID, OrderedAt),
    KEY IX_Orders_BillingAddressID (BillingAddressID),
    KEY IX_Orders_ShippingAddressID (ShippingAddressID),
    KEY IX_Orders_PaymentID (PaymentID),
    KEY IX_Orders_OrderStatusID (OrderStatusID, OrderedAt)
) ENGINE=InnoDB;

CREATE TABLE Payments (
    PaymentID         INT AUTO_INCREMENT PRIMARY KEY,
    OrderID           INT NOT NULL,
    PaymentMethodID   INT NOT NULL,
    Amount            DECIMAL(12,2) NOT NULL,
    Currency          CHAR(3) NOT NULL DEFAULT 'MAD',
    TransactionID     VARCHAR(150),
    ProviderReference VARCHAR(150),
    Status            TINYINT NOT NULL DEFAULT 0,
    PaidAt            DATETIME,
    CreatedAt         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Payments_Order  FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_Payments_Method FOREIGN KEY (PaymentMethodID) REFERENCES PaymentMethods(PaymentMethodID) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY UX_Payments_TransactionID (TransactionID),
    KEY IX_Payments_OrderID (OrderID),
    KEY IX_Payments_PaymentMethodID (PaymentMethodID),
    KEY IXF_Payments_Status (Status, CreatedAt)
) ENGINE=InnoDB;

ALTER TABLE Orders
    ADD CONSTRAINT FK_Orders_Payment FOREIGN KEY (PaymentID) REFERENCES Payments(PaymentID) ON DELETE SET NULL ON UPDATE CASCADE;

CREATE TABLE OrderItems (
    OrderItemID      INT AUTO_INCREMENT PRIMARY KEY,
    OrderID          INT NOT NULL,
    ProductID        INT NOT NULL,
    ProductVariantID INT,
    VendorProfileID  INT NOT NULL,
    Quantity         DECIMAL(10,2) NOT NULL DEFAULT 1,
    UnitPrice        DECIMAL(12,2) NOT NULL,
    Discount         DECIMAL(12,2) NOT NULL DEFAULT 0,
    Tax              DECIMAL(12,2) NOT NULL DEFAULT 0,
    Total            DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT FK_OrderItems_Order  FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_OrderItems_Product FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_OrderItems_Vendor  FOREIGN KEY (VendorProfileID) REFERENCES VendorProfiles(VendorProfileID) ON DELETE RESTRICT ON UPDATE CASCADE,
    KEY IX_OrderItems_OrderID (OrderID),
    KEY IX_OrderItems_ProductID (ProductID),
    KEY IX_OrderItems_ProductVariantID (ProductVariantID),
    KEY IX_OrderItems_VendorProfileID (VendorProfileID)
) ENGINE=InnoDB;


-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

CREATE TABLE Notifications (
    NotificationID     INT AUTO_INCREMENT PRIMARY KEY,
    UserID             INT NOT NULL,
    NotificationTypeID INT NOT NULL,
    Title              VARCHAR(255) NOT NULL,
    Body               VARCHAR(1000) NOT NULL,
    DataPayload        JSON,
    RelatedEntityType  VARCHAR(50),
    RelatedEntityID    INT,
    IsRead             TINYINT(1) NOT NULL DEFAULT 0,
    ReadAt             DATETIME,
    CreatedAt          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Notifications_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_Notifications_Type  FOREIGN KEY (NotificationTypeID) REFERENCES NotificationTypes(NotificationTypeID) ON DELETE RESTRICT ON UPDATE CASCADE,
    KEY IXF_Notifications_User_Unread (UserID, IsRead, CreatedAt),
    KEY IX_Notifications_User_All (UserID, CreatedAt),
    KEY IX_Notifications_NotificationTypeID (NotificationTypeID),
    KEY IX_Notifications_RelatedEntity (RelatedEntityType, RelatedEntityID)
) ENGINE=InnoDB;

CREATE TABLE UserDevices (
    UserDeviceID INT AUTO_INCREMENT PRIMARY KEY,
    UserID       INT NOT NULL,
    FCMToken     VARCHAR(255) NOT NULL,
    DeviceType   TINYINT NOT NULL,
    DeviceModel  VARCHAR(150),
    AppVersion   VARCHAR(20),
    IsActive     TINYINT(1) NOT NULL DEFAULT 1,
    LastUsedAt   DATETIME,
    CreatedAt    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_UserDevices_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_UserDevices_FCMToken (FCMToken),
    KEY IX_UserDevices_UserID (UserID)
) ENGINE=InnoDB;

CREATE TABLE UserNotificationPreferences (
    UserNotificationPreferenceID INT AUTO_INCREMENT PRIMARY KEY,
    UserID             INT NOT NULL,
    NotificationTypeID INT NOT NULL,
    PushEnabled        TINYINT(1) NOT NULL DEFAULT 1,
    UpdatedAt          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT FK_UserNotificationPreferences_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_UserNotificationPreferences_Type  FOREIGN KEY (NotificationTypeID) REFERENCES NotificationTypes(NotificationTypeID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_UserNotificationPreferences_User_Type (UserID, NotificationTypeID),
    KEY IX_UserNotificationPreferences_NotificationTypeID (NotificationTypeID)
) ENGINE=InnoDB;

CREATE TABLE NotificationDeliveryLog (
    DeliveryLogID INT AUTO_INCREMENT PRIMARY KEY,
    NotificationID INT NOT NULL,
    UserDeviceID   INT NOT NULL,
    Status         TINYINT NOT NULL DEFAULT 0,
    ErrorMessage   VARCHAR(500),
    AttemptedAt    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_NotificationDeliveryLog_Notification FOREIGN KEY (NotificationID) REFERENCES Notifications(NotificationID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_NotificationDeliveryLog_Device       FOREIGN KEY (UserDeviceID) REFERENCES UserDevices(UserDeviceID) ON DELETE CASCADE ON UPDATE CASCADE,
    KEY IX_NotificationDeliveryLog_NotificationID (NotificationID),
    KEY IX_NotificationDeliveryLog_UserDeviceID (UserDeviceID),
    KEY IXF_NotificationDeliveryLog_Failed (Status, AttemptedAt)
) ENGINE=InnoDB;


-- =============================================================================
-- RECOMMENDATION ENGINE FACT TABLES
-- =============================================================================

CREATE TABLE FAIT_EVENEMENT_CLIENT (
    id_evenement       INT AUTO_INCREMENT PRIMARY KEY,
    id_utilisateur     INT NOT NULL,
    id_annonce         INT NOT NULL,
    id_type_evenement  INT NOT NULL,
    score              INT NOT NULL DEFAULT 0,
    date_evenement     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_FAIT_EVENEMENT_CLIENT_User FOREIGN KEY (id_utilisateur) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_FAIT_EVENEMENT_CLIENT_Product FOREIGN KEY (id_annonce) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_FAIT_EVENEMENT_CLIENT_Type FOREIGN KEY (id_type_evenement) REFERENCES DIM_TYPE_EVENEMENT(id_type_evenement) ON DELETE RESTRICT ON UPDATE CASCADE,
    KEY IX_FAIT_EVENEMENT_CLIENT_utilisateur (id_utilisateur, date_evenement),
    KEY IX_FAIT_EVENEMENT_CLIENT_annonce (id_annonce, date_evenement),
    KEY IX_FAIT_EVENEMENT_CLIENT_type (id_type_evenement)
) ENGINE=InnoDB;

CREATE TABLE FAIT_SCORE_CLIENT_PRODUIT (
    id                    INT AUTO_INCREMENT PRIMARY KEY,
    id_utilisateur        INT NOT NULL,
    id_annonce            INT NOT NULL,
    score_total           INT NOT NULL DEFAULT 0,
    derniere_mise_a_jour  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_FAIT_SCORE_CLIENT_PRODUIT_User FOREIGN KEY (id_utilisateur) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_FAIT_SCORE_CLIENT_PRODUIT_Product FOREIGN KEY (id_annonce) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY UX_FAIT_SCORE_CLIENT_PRODUIT_user_product (id_utilisateur, id_annonce),
    KEY IX_FAIT_SCORE_CLIENT_PRODUIT_annonce (id_annonce, score_total)
) ENGINE=InnoDB;

CREATE TABLE ProductStatus (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    Code VARCHAR(20) NOT NULL UNIQUE,
    Libelle VARCHAR(50) NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ====================================================
-- PRODUCT OPTIONS COMBINATIONS (Variants)
-- ====================================================

CREATE TABLE ProductOptionsCombiniason (
    CombinationID       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ProductID           INT NOT NULL,
    SKU                 NVARCHAR(64) NULL,
    Price               DECIMAL(10,2) NOT NULL,
    CompareAtPrice      DECIMAL(10,2) NULL,
    Stock               INT NOT NULL DEFAULT 0,
    ImagePath           NVARCHAR(255) NULL,
    OptionsHash         CHAR(64) NOT NULL COMMENT 'SHA2 hash of sorted OptionIDs, prevents duplicate combos',
    IsDefault           BIT NOT NULL DEFAULT 0,
    IsActive            BIT NOT NULL DEFAULT 1,
    CreatedAt           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT FK_POC_Product
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE,

    CONSTRAINT UQ_POC_Product_SKU UNIQUE (ProductID, SKU),
    CONSTRAINT UQ_POC_Product_OptionsHash UNIQUE (ProductID, OptionsHash),

    INDEX IX_POC_Product (ProductID),
    INDEX IX_POC_Active (IsActive)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ====================================================
-- PRODUCT OPTIONS COMBINATION DETAILS (junction)
-- ====================================================

CREATE TABLE ProductOptionsCombiniasonDetails (
    CombinationDetailID        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    CombinationID               INT UNSIGNED NOT NULL,
    ProductsConfigAttributeID   INT NOT NULL,
    OptionID                    INT NOT NULL,

    CONSTRAINT FK_POCD_Combination
        FOREIGN KEY (CombinationID) REFERENCES ProductOptionsCombiniason(CombinationID)
        ON DELETE CASCADE,

    CONSTRAINT FK_POCD_Attribute
        FOREIGN KEY (ProductsConfigAttributeID) REFERENCES ProductsConfigAttribute(AttributeID),

    CONSTRAINT FK_POCD_Option
        FOREIGN KEY (OptionID) REFERENCES ConfigAttributeOptions(OptionID),

    -- Prevents same combination setting the same attribute twice
    CONSTRAINT UQ_POCD_Combination_Attribute UNIQUE (CombinationID, ProductsConfigAttributeID),

    INDEX IX_POCD_Option (OptionID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
ALTER TABLE SearchDictionary
    ADD INDEX IX_SearchDictionary_NormalizedText (NormalizedText);



CREATE TABLE ProductLikes (
    ProductLikeID   INT AUTO_INCREMENT PRIMARY KEY,
    UserID          INT NOT NULL,
    ProductID       INT NOT NULL,
    LikedAt         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT FK_ProductLikes_Users
        FOREIGN KEY (UserID) REFERENCES Users(UserID)
        ON DELETE CASCADE,

    CONSTRAINT FK_ProductLikes_Products
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE,

    -- prevents a user from liking the same product twice
    CONSTRAINT UQ_ProductLikes_User_Product UNIQUE (UserID, ProductID),

    -- speeds up "get all products a user liked" and "count likes per product"
    INDEX IDX_ProductLikes_UserID (UserID),
    INDEX IDX_ProductLikes_ProductID (ProductID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE ProductSearchIndex
ADD FULLTEXT INDEX FT_SearchText (SearchText);

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- OPTIONAL: seed a couple of lookup rows so the app has something to boot
-- against. Comment out if you'll seed via your own migration/SP layer.
-- =============================================================================
-- INSERT INTO OrderStatus (Name, Code, DisplayOrder) VALUES
--   ('En attente', 'PENDING', 1), ('Confirmée', 'CONFIRMED', 2),
--   ('Expédiée', 'SHIPPED', 3), ('Livrée', 'DELIVERED', 4), ('Annulée', 'CANCELLED', 5);
-- INSERT INTO Roles (Name, Code, IsSystem) VALUES
--   ('Admin', 'ADMIN', 1), ('Vendor', 'VENDOR', 1), ('Customer', 'CUSTOMER', 1);