-- =============================================================================
-- MARKETPLACE PLATFORM — FULL RANDOM DEV/TEST DATA GENERATOR
-- =============================================================================
-- Populates every table EXCEPT pure lookup tables:
--   Countries, Roles, PaymentMethods, OrderStatus, Units, ResourcesTypes,
--   ResourcesRoles, ProductStatus, PromotionDiscountTypes, PromotionScopeTypes,
--   PromotionStatuses  (all assumed already seeded by your init/seed scripts)
--
-- EXCEPTION — two lookup tables have no seed data anywhere in what's been
-- shared (NotificationTypes, DIM_TYPE_EVENEMENT), so a handful of minimal
-- rows are inserted for them (INSERT IGNORE, clearly marked "PREREQUISITE").
-- Without them, Notifications / FAIT_EVENEMENT_CLIENT have nothing to point
-- their FKs at.
--
-- Tables populated (grouped by area):
--   Users/Auth      : Users, UserExternalLogins, UserRoles, UserRefreshTokens,
--                      VendorProfiles, AdminProfiles, CustomerProfiles,
--                      Addresses, UserDevices, UserNotificationPreferences
--   Vendor finance  : PaymentInformations, BankAccounts, WithdrawHistory
--   Catalog         : Brands, Models, Categories, CategoryClosure,
--                      ProductsConfigAttribute, ConfigAttributeOptions, Tags
--   Products        : Products, ProductResources, ProductAllowedPayements,
--                      ProductDetails, ProductCategories, ProductTags,
--                      ProductOptionsCombiniason(+Details)
--   Search          : ProductSearchIndex, SearchDictionary, SearchSynonyms,
--                      SearchTermProductStats, ProductRankingFactors,
--                      RegionalProductStats, IPGeoLocations, UserSearchHistory
--   Cart/Wishlist   : Carts, CartItems, WishLists, WishListItems
--   Orders          : Orders, OrderItems, Payments
--   Notifications   : Notifications, NotificationDeliveryLog
--   Recommendation  : FAIT_EVENEMENT_CLIENT, FAIT_SCORE_CLIENT_PRODUIT
--   Promotions      : Promotions
--
-- SearchDictionary entries are populated with the same upsert semantics as
-- SP_CreateBrand / SP_CreateModel / SP_CreateProduct / SP_CreateTag /
-- SP_CreateConfigAttributeOption* — via a single INSERT ... ON DUPLICATE KEY
-- UPDATE, which is behaviourally equivalent to their per-row IF EXISTS/ELSE
-- pattern but bulk-safe. SourceType mapping used (same as your SPs, except
-- Models — see note above):
--   1=Category  2=Tag  3=Brand  4=ProductsConfigAttribute
--   5=ConfigAttributeOption  6=Product  7=Model (deviation, see header note)
--
-- Re-running: safe. All unique text fields get a UUID_SHORT() suffix, and
-- every "capture range" step re-scopes itself to the current run only.
--
-- FIX (this version): section 12's ProductOptionsCombiniasonDetails insert
-- used a single UNION ALL statement that referenced the TEMPORARY table
-- ComboCandidates twice. MySQL doesn't allow a TEMPORARY table to be opened
-- twice within one statement (Error 1137: Can't reopen table). Split into
-- two separate INSERT statements — same result, no reopen.
-- =============================================================================

USE marketplace_db;
SET FOREIGN_KEY_CHECKS = 0;
SET SESSION cte_max_recursion_depth = 20000;

-- ---------------------------------------------------------------------------
-- CONFIG
-- ---------------------------------------------------------------------------
SET @NB_VENDORS          = 25;
SET @NB_CUSTOMERS        = 200;
SET @NB_ADMINS           = 3;
SET @NB_BRANDS           = 15;
SET @NB_MODELS           = 45;
SET @NB_CATEGORIES       = 20;
SET @NB_TAGS             = 30;
SET @NB_PRODUCTS         = 500;
SET @NB_ORDERS           = 400;
SET @MAX_ITEMS_PER_ORDER = 5;
SET @NB_IPGEO            = 100;
SET @NB_SEARCH_LOGS      = 300;
SET @NB_EVENTS           = 1000;

DROP TEMPORARY TABLE IF EXISTS Seq;
CREATE TEMPORARY TABLE Seq (n INT PRIMARY KEY);
INSERT INTO Seq (n)
WITH RECURSIVE cte (n) AS (
    SELECT 0 UNION ALL SELECT n + 1 FROM cte WHERE n < 9999
)
SELECT n FROM cte;


-- =============================================================================
-- PREREQUISITE LOOKUP ROWS (only added because they're missing upstream —
-- NOT part of the "generate random data" request; INSERT IGNORE, idempotent)
-- =============================================================================
INSERT IGNORE INTO NotificationTypes (Code, Category, TitleTemplate, BodyTemplate) VALUES
    ('ORDER_CONFIRMED',   1, 'Commande confirmée',  'Votre commande {{order_number}} a été confirmée.'),
    ('ORDER_SHIPPED',     1, 'Commande expédiée',   'Votre commande {{order_number}} a été expédiée.'),
    ('PRODUCT_VALIDATED', 2, 'Produit validé',      'Votre produit {{product_name}} a été validé.'),
    ('PROMO_STARTED',     3, 'Nouvelle promotion',  'La promotion {{promo_name}} vient de démarrer.'),
    ('PAYMENT_RECEIVED',  4, 'Paiement reçu',       'Votre paiement de {{amount}} a été reçu.');

INSERT IGNORE INTO DIM_TYPE_EVENEMENT (code, nom, points) VALUES
    ('VIEW',         'Vue produit',    1),
    ('CLICK',        'Clic produit',   2),
    ('FAVORITE',     'Ajout favoris',  5),
    ('ADD_TO_CART',  'Ajout panier',   8),
    ('PURCHASE',     'Achat',         20);

-- Same treatment for ResourcesTypes/ResourcesRoles: your seed script defines
-- these, but the run that hit "ResourcesTypeID cannot be null" shows they
-- weren't actually present. INSERT IGNORE no-ops if they already exist.
INSERT IGNORE INTO ResourcesTypes (Name) VALUES ('Pdf'), ('Video'), ('Images'), ('Json');
INSERT IGNORE INTO ResourcesRoles (Label) VALUES ('Pour Administrateur'), ('Pour Visiteur');

-- Resolve once into variables instead of re-running these subqueries per insert.
SET @rtype_images  = (SELECT ID FROM ResourcesTypes WHERE Name = 'Images' LIMIT 1);
SET @rrole_visitor = (SELECT RoleID FROM ResourcesRoles WHERE Label = 'Pour Visiteur' LIMIT 1);


-- =============================================================================
-- 1. VENDORS
-- =============================================================================
INSERT INTO Users (PublicID, FirstName, LastName, DisplayName, Email, PasswordHash, IsActive, HasPassword, EmailVerified)
SELECT UUID(), FirstName, LastName, CONCAT(FirstName, ' ', LastName), Email, 'dummyhash123', 1, 1, 1
FROM (
    SELECT
        ELT(1 + FLOOR(RAND() * 10), 'Youssef','Fatima','Karim','Salma','Omar','Nadia','Hicham','Layla','Amine','Meryem') AS FirstName,
        ELT(1 + FLOOR(RAND() * 10), 'Benali','Alaoui','Tazi','Idrissi','Bennani','Cherkaoui','Fassi','Amrani','Ouazzani','Ziani') AS LastName,
        CONCAT('vendor_', n, '_', UUID_SHORT(), '@example.com') AS Email
    FROM Seq WHERE n < @NB_VENDORS
) x;
SET @vendor_count_actual = ROW_COUNT();
SET @vendor_first_id = LAST_INSERT_ID();

INSERT INTO VendorProfiles (UserID, StoreName, Description, Rating, ReviewCount, IdentityVerified, BusinessVerified, BankVerified, VerificationStatus, IsApproved)
SELECT
    UserID,
    CONCAT(
        ELT(1 + FLOOR(RAND() * 8), 'Atlas','Sahara','Medina','Souk','Marrakech','Fes','Rif','Ocean'), ' ',
        ELT(1 + FLOOR(RAND() * 6), 'Store','Boutique','Market','Trading','Shop','Bazaar')
    ),
    'Vendeur généré automatiquement pour les besoins de développement.',
    ROUND(3 + RAND() * 2, 2), FLOOR(RAND() * 300),
    1, 1, 1, 1, 1
FROM Users WHERE UserID BETWEEN @vendor_first_id AND @vendor_first_id + @vendor_count_actual - 1;

INSERT INTO UserRoles (UserID, RoleID)
SELECT UserID, 2 FROM Users WHERE UserID BETWEEN @vendor_first_id AND @vendor_first_id + @vendor_count_actual - 1;


-- =============================================================================
-- 2. CUSTOMERS
-- =============================================================================
INSERT INTO Users (PublicID, FirstName, LastName, DisplayName, Email, PasswordHash, IsActive, HasPassword, EmailVerified)
SELECT UUID(), FirstName, LastName, CONCAT(FirstName, ' ', LastName), Email, 'dummyhash123', 1, 1, 1
FROM (
    SELECT
        ELT(1 + FLOOR(RAND() * 10), 'Sara','Mehdi','Imane','Yassine','Rania','Anas','Khadija','Reda','Zineb','Adam') AS FirstName,
        ELT(1 + FLOOR(RAND() * 10), 'El Amrani','Bensaid','Lahlou','Berrada','Chaoui','Naciri','Sbai','Kadiri','Filali','Rifai') AS LastName,
        CONCAT('customer_', n, '_', UUID_SHORT(), '@example.com') AS Email
    FROM Seq WHERE n < @NB_CUSTOMERS
) x;
SET @customer_count_actual = ROW_COUNT();
SET @customer_first_id = LAST_INSERT_ID();

INSERT INTO CustomerProfiles (UserID, LoyaltyPoints, AcceptMarketingEmails)
SELECT UserID, FLOOR(RAND() * 1000), IF(RAND() < 0.5, 1, 0)
FROM Users WHERE UserID BETWEEN @customer_first_id AND @customer_first_id + @customer_count_actual - 1;

INSERT INTO UserRoles (UserID, RoleID)
SELECT UserID, 3 FROM Users WHERE UserID BETWEEN @customer_first_id AND @customer_first_id + @customer_count_actual - 1;

INSERT INTO Addresses (UserID, FullName, Phone, Country, Region, City, PostalCode, AddressLine1, IsDefaultBilling, IsDefaultShipping)
SELECT
    u.UserID, u.DisplayName,
    CONCAT('06', LPAD(FLOOR(RAND() * 100000000), 8, '0')),
    'Maroc',
    ELT(1 + FLOOR(RAND() * 6), 'Casablanca-Settat','Rabat-Salé-Kénitra','Marrakech-Safi','Fès-Meknès','Tanger-Tétouan-Al Hoceïma','Souss-Massa'),
    ELT(1 + FLOOR(RAND() * 6), 'Casablanca','Rabat','Marrakech','Fès','Tanger','Agadir'),
    LPAD(FLOOR(RAND() * 99999), 5, '0'),
    CONCAT(FLOOR(RAND() * 300), ' Rue ', ELT(1 + FLOOR(RAND() * 5), 'Hassan II','Mohammed V','Al Massira','Zerktouni','Anfa')),
    1, 1
FROM Users u WHERE u.UserID BETWEEN @customer_first_id AND @customer_first_id + @customer_count_actual - 1;


-- =============================================================================
-- 3. ADMINS
-- =============================================================================
INSERT INTO Users (PublicID, FirstName, LastName, DisplayName, Email, PasswordHash, IsActive, HasPassword, EmailVerified)
SELECT UUID(), FirstName, LastName, CONCAT(FirstName, ' ', LastName), Email, 'dummyhash123', 1, 1, 1
FROM (
    SELECT
        ELT(1 + FLOOR(RAND() * 6), 'Hassan','Latifa','Younes','Samira','Tarik','Nawal') AS FirstName,
        ELT(1 + FLOOR(RAND() * 6), 'Benjelloun','El Fassi','Chraibi','Belkadi','Skalli','Tahiri') AS LastName,
        CONCAT('admin_', n, '_', UUID_SHORT(), '@example.com') AS Email
    FROM Seq WHERE n < @NB_ADMINS
) x;
SET @admin_count_actual = ROW_COUNT();
SET @admin_first_id = LAST_INSERT_ID();

INSERT INTO AdminProfiles (UserID, EmployeeNumber, CIN, Position, Status, IdentityVerified, HireDate)
SELECT UserID, CONCAT('EMP-', UserID, '-', UUID_SHORT()), CONCAT('CIN-', UserID, '-', UUID_SHORT()),
       'Modérateur', 1, 1, DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 1000) DAY)
FROM Users WHERE UserID BETWEEN @admin_first_id AND @admin_first_id + @admin_count_actual - 1;

INSERT INTO UserRoles (UserID, RoleID)
SELECT UserID, 1 FROM Users WHERE UserID BETWEEN @admin_first_id AND @admin_first_id + @admin_count_actual - 1;

-- Convenience range covering ALL generated users (vendors+customers+admins),
-- valid because nothing else inserts into Users between sections 1-3 above.
SET @alluser_first_id = @vendor_first_id;
SET @alluser_last_id   = @admin_first_id + @admin_count_actual - 1;


-- =============================================================================
-- 4. AUTH EXTRAS: UserExternalLogins, UserRefreshTokens, UserDevices,
--                 UserNotificationPreferences
-- =============================================================================
INSERT IGNORE INTO UserExternalLogins (UserID, Provider, ProviderUserID, Email, DisplayName, IsVerifiedEmail)
SELECT UserID, 1 + FLOOR(RAND() * 3), CONCAT('EXT-', UserID, '-', UUID_SHORT()), Email, DisplayName, 1
FROM Users
WHERE UserID BETWEEN @alluser_first_id AND @alluser_last_id AND RAND() < 0.2;

INSERT INTO UserRefreshTokens (UserID, TokenHash, IPAddress, ExpiresAt)
SELECT UserID, CONCAT('TOKEN-', UserID, '-', UUID_SHORT()),
       CONCAT(FLOOR(RAND() * 255), '.', FLOOR(RAND() * 255), '.', FLOOR(RAND() * 255), '.', FLOOR(RAND() * 255)),
       DATE_ADD(NOW(), INTERVAL 30 DAY)
FROM Users WHERE UserID BETWEEN @alluser_first_id AND @alluser_last_id;

INSERT IGNORE INTO UserDevices (UserID, FCMToken, DeviceType, DeviceModel, AppVersion, IsActive, LastUsedAt)
SELECT UserID, CONCAT('FCM-', UserID, '-', UUID_SHORT()), 1 + FLOOR(RAND() * 3),
       ELT(1 + FLOOR(RAND() * 4), 'iPhone 14', 'Samsung Galaxy S23', 'Xiaomi Redmi Note', 'Pixel 7'),
       CONCAT(1 + FLOOR(RAND() * 3), '.', FLOOR(RAND() * 10), '.', FLOOR(RAND() * 10)),
       1, NOW()
FROM Users WHERE UserID BETWEEN @alluser_first_id AND @alluser_last_id AND RAND() < 0.5;

INSERT IGNORE INTO UserNotificationPreferences (UserID, NotificationTypeID, PushEnabled)
SELECT u.UserID, nt.NotificationTypeID, IF(RAND() < 0.85, 1, 0)
FROM Users u JOIN NotificationTypes nt
WHERE u.UserID BETWEEN @alluser_first_id AND @alluser_last_id;


-- =============================================================================
-- 5. VENDOR FINANCE: PaymentInformations, BankAccounts, WithdrawHistory
-- =============================================================================
INSERT INTO PaymentInformations (UserID, PaymentMethodID, AccountName, AccountNumber, IBAN, IsDefault, IsVerified)
SELECT UserID, 1, DisplayName, CONCAT('ACC', UserID, UUID_SHORT()),
       CONCAT('MA', LPAD(FLOOR(RAND() * 99999999), 20, '0')), 1, IF(RAND() < 0.7, 1, 0)
FROM Users WHERE UserID BETWEEN @vendor_first_id AND @vendor_first_id + @vendor_count_actual - 1;

INSERT INTO BankAccounts (VendorProfileID, CurrentBalance, WithdrawableBalance, PendingBalance)
SELECT vp.VendorProfileID, ROUND(RAND() * 50000, 2), ROUND(RAND() * 30000, 2), ROUND(RAND() * 5000, 2)
FROM VendorProfiles vp WHERE vp.UserID BETWEEN @vendor_first_id AND @vendor_first_id + @vendor_count_actual - 1;

INSERT INTO WithdrawHistory (BankAccountID, PaymentMethodID, Amount, ExternalReference, Status, RequestedAt, ProcessedAt)
SELECT ba.BankAccountID, 1, ROUND(500 + RAND() * 5000, 2), CONCAT('WD-', ba.BankAccountID, '-', UUID_SHORT()),
       IF(RAND() < 0.8, 1, 0),
       DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 60) DAY),
       IF(RAND() < 0.8, NOW(), NULL)
FROM BankAccounts ba
JOIN VendorProfiles vp ON vp.VendorProfileID = ba.VendorProfileID
JOIN Seq slot ON slot.n < 3
WHERE vp.UserID BETWEEN @vendor_first_id AND @vendor_first_id + @vendor_count_actual - 1 AND RAND() < 0.4;


-- =============================================================================
-- 6. BRANDS  (+ SearchDictionary, mirrors SP_CreateBrand)
-- =============================================================================
INSERT INTO Brands (Name, Slug, CountryID, IsActive)
SELECT
    CONCAT(ELT(1 + FLOOR(RAND() * 10), 'Nova','Zenith','Orbit','Pulse','Vertex','Aster','Lumen','Trek','Halo','Drift'), ' ',
           ELT(1 + FLOOR(RAND() * 6), 'Tech','Wear','Home','Sport','Kids','Beauty')),
    CONCAT('brand-gen-', n, '-', UUID_SHORT()),
    (SELECT CountryID FROM Countries ORDER BY RAND() LIMIT 1),
    1
FROM Seq WHERE n < @NB_BRANDS;
SET @brand_count_actual = ROW_COUNT();
SET @brand_first_id = LAST_INSERT_ID();

INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
SELECT Name, LOWER(TRIM(Name)), 3, BrandID
FROM Brands WHERE BrandID BETWEEN @brand_first_id AND @brand_first_id + @brand_count_actual - 1
UNION ALL
SELECT CONCAT(b.Name, ' ', c.Name), LOWER(TRIM(CONCAT(b.Name, ' ', c.Name))), 3, b.BrandID
FROM Brands b JOIN Countries c ON c.CountryID = b.CountryID
WHERE b.BrandID BETWEEN @brand_first_id AND @brand_first_id + @brand_count_actual - 1
ON DUPLICATE KEY UPDATE DisplayText = VALUES(DisplayText), SourceType = VALUES(SourceType), SourceID = VALUES(SourceID), IsActive = 1, UpdatedAt = NOW();


-- =============================================================================
-- 7. MODELS  (+ SearchDictionary, mirrors SP_CreateModel — SourceType 7, see header note)
-- =============================================================================
DROP TEMPORARY TABLE IF EXISTS BrandPool;
CREATE TEMPORARY TABLE BrandPool (rn INT PRIMARY KEY AUTO_INCREMENT, BrandID INT);
INSERT INTO BrandPool (BrandID) SELECT BrandID FROM Brands;
SET @brand_pool_size = (SELECT COUNT(*) FROM BrandPool);

INSERT INTO Models (BrandID, Name, Code, ReleaseYear)
SELECT
    bp.BrandID,
    CONCAT(ELT(1 + FLOOR(RAND() * 10), 'Alpha','Beta','Gamma','Delta','Omega','Nova','Prime','Edge','Core','Flex'), '-', s.n),
    CONCAT('MDL-', s.n, '-', UUID_SHORT()),
    2018 + FLOOR(RAND() * 8)
FROM Seq s
JOIN BrandPool bp ON bp.rn = 1 + FLOOR(RAND() * @brand_pool_size)
WHERE s.n < @NB_MODELS;
SET @model_count_actual = ROW_COUNT();
SET @model_first_id = LAST_INSERT_ID();

INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
SELECT m.Name, LOWER(TRIM(m.Name)), 7, m.ModelID
FROM Models m WHERE m.ModelID BETWEEN @model_first_id AND @model_first_id + @model_count_actual - 1
UNION ALL
SELECT CONCAT(b.Name, ' ', m.Name), LOWER(TRIM(CONCAT(b.Name, ' ', m.Name))), 7, m.ModelID
FROM Models m JOIN Brands b ON b.BrandID = m.BrandID
WHERE m.ModelID BETWEEN @model_first_id AND @model_first_id + @model_count_actual - 1
UNION ALL
SELECT CONCAT(c.Name, ' ', b.Name, ' ', m.Name), LOWER(TRIM(CONCAT(c.Name, ' ', b.Name, ' ', m.Name))), 7, m.ModelID
FROM Models m JOIN Brands b ON b.BrandID = m.BrandID JOIN Countries c ON c.CountryID = b.CountryID
WHERE m.ModelID BETWEEN @model_first_id AND @model_first_id + @model_count_actual - 1
ON DUPLICATE KEY UPDATE DisplayText = VALUES(DisplayText), SourceType = VALUES(SourceType), SourceID = VALUES(SourceID), IsActive = 1, UpdatedAt = NOW();


-- =============================================================================
-- 8. CATEGORIES  (+ CategoryClosure, mirrors SP_CreateCategory)
-- =============================================================================
INSERT INTO Categories (ParentCategoryID, Name, Slug, IsActive, DisplayOrder)
SELECT
    ELT(1 + FLOOR(RAND() * 3), 1, 2, 3),
    CONCAT('Sous-catégorie ', n),
    CONCAT('subcat-gen-', n, '-', UUID_SHORT()),
    1, n
FROM Seq WHERE n < @NB_CATEGORIES;
SET @cat_count_actual = ROW_COUNT();
SET @cat_first_id = LAST_INSERT_ID();

INSERT INTO CategoryClosure (AncestorID, DescendantID, Depth)
SELECT CategoryID, CategoryID, 0
FROM Categories WHERE CategoryID BETWEEN @cat_first_id AND @cat_first_id + @cat_count_actual - 1;

INSERT INTO CategoryClosure (AncestorID, DescendantID, Depth)
SELECT cc.AncestorID, c.CategoryID, cc.Depth + 1
FROM Categories c JOIN CategoryClosure cc ON cc.DescendantID = c.ParentCategoryID
WHERE c.CategoryID BETWEEN @cat_first_id AND @cat_first_id + @cat_count_actual - 1;

INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
SELECT Name, LOWER(TRIM(Name)), 1, CategoryID
FROM Categories WHERE CategoryID BETWEEN @cat_first_id AND @cat_first_id + @cat_count_actual - 1
ON DUPLICATE KEY UPDATE DisplayText = VALUES(DisplayText), SourceType = VALUES(SourceType), SourceID = VALUES(SourceID), IsActive = 1, UpdatedAt = NOW();

DROP TEMPORARY TABLE IF EXISTS CategoryPool;
CREATE TEMPORARY TABLE CategoryPool (rn INT PRIMARY KEY AUTO_INCREMENT, CategoryID INT);
INSERT INTO CategoryPool (CategoryID) SELECT CategoryID FROM Categories;
SET @category_pool_size = (SELECT COUNT(*) FROM CategoryPool);


-- =============================================================================
-- 9. CONFIG ATTRIBUTES (Couleur/Taille) + OPTIONS  (mirrors SP_Create*ConfigAttribute*)
-- =============================================================================
INSERT IGNORE INTO ProductsConfigAttribute (Name, DisplayOrder) VALUES ('Couleur', 1), ('Taille', 2);
SET @attr_color = (SELECT AttributeID FROM ProductsConfigAttribute WHERE Name = 'Couleur');
SET @attr_size  = (SELECT AttributeID FROM ProductsConfigAttribute WHERE Name = 'Taille');

INSERT IGNORE INTO ConfigAttributeOptions (ProductsConfigAttributeID, OptionLabel, OptionValue, DisplayOrder) VALUES
    (@attr_color, 'Rouge', 'red',   1), (@attr_color, 'Bleu',  'blue',  2),
    (@attr_color, 'Noir',  'black', 3), (@attr_color, 'Blanc', 'white', 4),
    (@attr_size,  'S', 'S', 1), (@attr_size, 'M', 'M', 2), (@attr_size, 'L', 'L', 3), (@attr_size, 'XL', 'XL', 4);

INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
SELECT Name, LOWER(TRIM(Name)), 4, AttributeID FROM ProductsConfigAttribute
UNION ALL
SELECT o.OptionLabel, LOWER(TRIM(o.OptionLabel)), 5, o.OptionID FROM ConfigAttributeOptions o
UNION ALL
SELECT CONCAT(pa.Name, ' ', o.OptionLabel), LOWER(TRIM(CONCAT(pa.Name, ' ', o.OptionLabel))), 5, o.OptionID
FROM ConfigAttributeOptions o JOIN ProductsConfigAttribute pa ON pa.AttributeID = o.ProductsConfigAttributeID
ON DUPLICATE KEY UPDATE DisplayText = VALUES(DisplayText), SourceType = VALUES(SourceType), SourceID = VALUES(SourceID), IsActive = 1, UpdatedAt = NOW();


-- =============================================================================
-- 10. TAGS  (+ SearchDictionary, mirrors SP_CreateTag)
-- =============================================================================
INSERT INTO Tags (Name, Color, Description)
SELECT
    CONCAT(ELT(1 + FLOOR(RAND() * 12), 'Promo','Nouveauté','Bestseller','Éco','Local','Premium','Soldes','Tendance','Édition Limitée','Fait Main','Bio','Recyclé'), '-', n),
    CONCAT('#', LPAD(HEX(FLOOR(RAND() * 16777215)), 6, '0')),
    'Tag généré automatiquement.'
FROM Seq WHERE n < @NB_TAGS;
SET @tag_count_actual = ROW_COUNT();
SET @tag_first_id = LAST_INSERT_ID();

INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
SELECT Name, LOWER(TRIM(Name)), 2, TagID
FROM Tags WHERE TagID BETWEEN @tag_first_id AND @tag_first_id + @tag_count_actual - 1
ON DUPLICATE KEY UPDATE DisplayText = VALUES(DisplayText), SourceType = VALUES(SourceType), SourceID = VALUES(SourceID), IsActive = 1, UpdatedAt = NOW();

DROP TEMPORARY TABLE IF EXISTS TagPool;
CREATE TEMPORARY TABLE TagPool (rn INT PRIMARY KEY AUTO_INCREMENT, TagID INT);
INSERT INTO TagPool (TagID) SELECT TagID FROM Tags;
SET @tag_pool_size = (SELECT COUNT(*) FROM TagPool);


-- =============================================================================
-- 11. PRODUCTS  (+ SearchDictionary mirrors SP_CreateProduct's 4 entries)
-- =============================================================================
DROP TEMPORARY TABLE IF EXISTS VendorPool;
CREATE TEMPORARY TABLE VendorPool (rn INT PRIMARY KEY AUTO_INCREMENT, UserID INT);
INSERT INTO VendorPool (UserID) SELECT UserID FROM VendorProfiles;
SET @vendor_pool_size = (SELECT COUNT(*) FROM VendorPool);

-- One "no model" slot per brand (real catalogs have plenty of model-less
-- products) plus one slot per generated model, so BrandID/ModelID stay
-- consistent with each other for every product.
DROP TEMPORARY TABLE IF EXISTS BrandModelPool;
CREATE TEMPORARY TABLE BrandModelPool (rn INT PRIMARY KEY AUTO_INCREMENT, BrandID INT, ModelID INT NULL);
INSERT INTO BrandModelPool (BrandID, ModelID) SELECT BrandID, NULL FROM Brands;
INSERT INTO BrandModelPool (BrandID, ModelID) SELECT BrandID, ModelID FROM Models;
SET @brandmodel_pool_size = (SELECT COUNT(*) FROM BrandModelPool);

-- NOTE: Products.VendorID's real FK target is Users(UserID) per the schema
-- (FK_Products_Vendor) — see earlier note about some SPs comparing it to
-- VendorProfileID instead. This script follows the actual FK.
INSERT INTO Products (VendorID, BrandID, ModelID, Name, Barcode, Description, BasePrice, Stock, Status, IsActive, CreatedAt)
SELECT
    vp.UserID, bmp.BrandID, bmp.ModelID,
    CONCAT(
        ELT(1 + FLOOR(RAND() * 12), 'Smartphone','Casque Audio','Sac à dos','Montre','Chaussures','Lampe','Chaise','Table','Veste','Clavier','Souris','Tapis'),
        ' ', ELT(1 + FLOOR(RAND() * 6), 'Pro','Max','Lite','Plus','Classic','Eco'), ' ', s.n
    ),
    CONCAT('BC', LPAD(s.n, 8, '0'), '-', UUID_SHORT()),
    'Produit généré automatiquement pour les besoins de développement.',
    ROUND(20 + RAND() * 2000, 2),
    FLOOR(RAND() * 500),
    CASE WHEN RAND() < 0.70 THEN 2 WHEN RAND() < 0.85 THEN 1 WHEN RAND() < 0.95 THEN 3 ELSE 4 END,
    IF(RAND() < 0.8, 1, 0),
    DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY)
FROM Seq s
JOIN VendorPool vp ON vp.rn = 1 + FLOOR(RAND() * @vendor_pool_size)
JOIN BrandModelPool bmp ON bmp.rn = 1 + FLOOR(RAND() * @brandmodel_pool_size)
WHERE s.n < @NB_PRODUCTS;
SET @product_count_actual = ROW_COUNT();
SET @product_first_id = LAST_INSERT_ID();

INSERT INTO ProductCategories (ProductID, CategoryID, IsPrimary)
SELECT p.ProductID, cp.CategoryID, 1
FROM Products p JOIN CategoryPool cp ON cp.rn = 1 + FLOOR(RAND() * @category_pool_size)
WHERE p.ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1;

INSERT INTO ProductResources (ProductID, ResourcesPath, ResourcesTypeID, ResourceRoleID)
SELECT ProductID, CONCAT('https://picsum.photos/seed/', ProductID, '/600/600'),
       (SELECT ID FROM ResourcesTypes WHERE Name = 'Images'),
       (SELECT RoleID FROM ResourcesRoles WHERE Label = 'Pour Visiteur')
FROM Products WHERE ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1;

INSERT INTO ProductSearchIndex (ProductID, SearchText)
SELECT p.ProductID, CONCAT_WS(' ', p.Name, b.Name, m.Name)
FROM Products p LEFT JOIN Brands b ON b.BrandID = p.BrandID LEFT JOIN Models m ON m.ModelID = p.ModelID
WHERE p.ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1;

INSERT IGNORE INTO ProductAllowedPayements (ProductID, PayementMethodID)
SELECT ProductID, 1 FROM Products WHERE ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1
UNION ALL
SELECT ProductID, 2 FROM Products WHERE ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1 AND RAND() < 0.6;

-- ~50% get a color detail, ~40% get a size detail (independent, like a real catalog)
INSERT INTO ProductDetails (ProductID, ProductsConfigAttributeID, OptionID)
SELECT p.ProductID, @attr_color,
       (SELECT OptionID FROM ConfigAttributeOptions WHERE ProductsConfigAttributeID = @attr_color ORDER BY RAND() LIMIT 1)
FROM Products p
WHERE p.ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1 AND RAND() < 0.5;

INSERT INTO ProductDetails (ProductID, ProductsConfigAttributeID, OptionID)
SELECT p.ProductID, @attr_size,
       (SELECT OptionID FROM ConfigAttributeOptions WHERE ProductsConfigAttributeID = @attr_size ORDER BY RAND() LIMIT 1)
FROM Products p
WHERE p.ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1 AND RAND() < 0.4;

-- 1-3 tags per product, ~50% chance per slot
INSERT IGNORE INTO ProductTags (ProductID, TagID)
SELECT p.ProductID, tp.TagID
FROM Products p
JOIN Seq slot ON slot.n < 3
JOIN TagPool tp ON tp.rn = 1 + FLOOR(RAND() * @tag_pool_size)
WHERE p.ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1 AND RAND() < 0.5;

-- SearchDictionary — mirrors SP_CreateProduct's 4 entries: name; brand+name;
-- brand+model+name; model+name
INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
SELECT p.Name, LOWER(TRIM(p.Name)), 6, p.ProductID
FROM Products p WHERE p.ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1
UNION ALL
SELECT CONCAT(b.Name, ' ', p.Name), LOWER(TRIM(CONCAT(b.Name, ' ', p.Name))), 6, p.ProductID
FROM Products p JOIN Brands b ON b.BrandID = p.BrandID
WHERE p.ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1
UNION ALL
SELECT CONCAT(b.Name, ' ', m.Name, ' ', p.Name), LOWER(TRIM(CONCAT(b.Name, ' ', m.Name, ' ', p.Name))), 6, p.ProductID
FROM Products p JOIN Brands b ON b.BrandID = p.BrandID JOIN Models m ON m.ModelID = p.ModelID
WHERE p.ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1
UNION ALL
SELECT CONCAT(m.Name, ' ', p.Name), LOWER(TRIM(CONCAT(m.Name, ' ', p.Name))), 6, p.ProductID
FROM Products p JOIN Models m ON m.ModelID = p.ModelID
WHERE p.ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1
ON DUPLICATE KEY UPDATE DisplayText = VALUES(DisplayText), SourceType = VALUES(SourceType), SourceID = VALUES(SourceID), IsActive = 1, UpdatedAt = NOW();


-- =============================================================================
-- 12. PRODUCT VARIANTS (ProductOptionsCombiniason + Details)
--     Mirrors SP_CreateProductCombination's hashing logic (sorted attrId:optionId
--     pairs, SHA2-256), materialized in a temp table so the hash used for the
--     INSERT matches the hash used to join Details back to the right combo.
--
--     NOTE: the ProductOptionsCombiniasonDetails insert is split into two
--     separate statements (one for color, one for size) instead of a single
--     UNION ALL — MySQL raises "Error 1137: Can't reopen table" if a
--     TEMPORARY table (ComboCandidates) is referenced twice in one statement.
-- =============================================================================
DROP TEMPORARY TABLE IF EXISTS ComboTemplate;
CREATE TEMPORARY TABLE ComboTemplate (tmpl_id INT PRIMARY KEY AUTO_INCREMENT, ColorOptionID INT, SizeOptionID INT);
INSERT INTO ComboTemplate (ColorOptionID, SizeOptionID)
SELECT co.OptionID, so.OptionID
FROM ConfigAttributeOptions co
JOIN ConfigAttributeOptions so ON so.ProductsConfigAttributeID = @attr_size
WHERE co.ProductsConfigAttributeID = @attr_color;

DROP TEMPORARY TABLE IF EXISTS ComboCandidates;
CREATE TEMPORARY TABLE ComboCandidates AS
SELECT
    p.ProductID,
    CONCAT('SKU-', p.ProductID, '-', ct.tmpl_id) AS SKU,
    ct.ColorOptionID,
    ct.SizeOptionID,
    ROUND(p.BasePrice * (0.9 + RAND() * 0.3), 2) AS Price,
    ROUND(p.BasePrice * 1.2, 2) AS CompareAtPrice,
    FLOOR(RAND() * 100) AS Stock,
    SHA2(CONCAT(@attr_color, ':', ct.ColorOptionID, '-', @attr_size, ':', ct.SizeOptionID), 256) AS OptionsHash,
    ROW_NUMBER() OVER (PARTITION BY p.ProductID ORDER BY ct.tmpl_id) = 1 AS IsDefault
FROM Products p
JOIN ComboTemplate ct
WHERE p.ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1
  AND RAND() < 0.15;  -- ~15% of (product, color+size) pairs get a variant row

ALTER TABLE ComboCandidates ADD PRIMARY KEY (ProductID, SKU);

INSERT INTO ProductOptionsCombiniason (ProductID, SKU, Price, CompareAtPrice, Stock, OptionsHash, IsDefault)
SELECT ProductID, SKU, Price, CompareAtPrice, Stock, OptionsHash, IsDefault
FROM ComboCandidates;

-- Color detail rows (split from the old UNION ALL — see NOTE above)
INSERT INTO ProductOptionsCombiniasonDetails (CombinationID, ProductsConfigAttributeID, OptionID)
SELECT c.CombinationID, @attr_color, cc.ColorOptionID
FROM ProductOptionsCombiniason c
JOIN ComboCandidates cc ON cc.ProductID = c.ProductID AND cc.SKU = c.SKU;

-- Size detail rows
INSERT INTO ProductOptionsCombiniasonDetails (CombinationID, ProductsConfigAttributeID, OptionID)
SELECT c.CombinationID, @attr_size, cc.SizeOptionID
FROM ProductOptionsCombiniason c
JOIN ComboCandidates cc ON cc.ProductID = c.ProductID AND cc.SKU = c.SKU;


-- =============================================================================
-- 13. SEARCH ANALYTICS: SearchSynonyms, SearchTermProductStats,
--     ProductRankingFactors, RegionalProductStats, IPGeoLocations,
--     UserSearchHistory
-- =============================================================================
INSERT IGNORE INTO SearchSynonyms (Term, NormalizedTerm, MapsToSearchTermID, LanguageCode)
SELECT CONCAT(sd.DisplayText, 's'), LOWER(TRIM(CONCAT(sd.DisplayText, 's'))), sd.SearchTermID, 'fr'
FROM SearchDictionary sd WHERE sd.SourceType = 6 ORDER BY RAND() LIMIT 30;

INSERT INTO SearchTermProductStats (SearchTermID, ProductID, ImpressionCount, ClickCount, PurchaseCount, ClickThroughRate, ConversionRate, LastInteractionAt)
SELECT SearchTermID, ProductID, imp, clk, pur,
       ROUND(clk / imp, 5),
       ROUND(pur / clk, 5),
       NOW()
FROM (
    SELECT sd.SearchTermID, sd.SourceID AS ProductID,
           GREATEST(1, FLOOR(RAND() * 1000)) AS imp,
           GREATEST(1, FLOOR(RAND() * 200)) AS clk,
           FLOOR(RAND() * 50) AS pur
    FROM SearchDictionary sd
    WHERE sd.SourceType = 6 AND sd.SourceID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1
) x
ON DUPLICATE KEY UPDATE ImpressionCount = VALUES(ImpressionCount), ClickCount = VALUES(ClickCount), PurchaseCount = VALUES(PurchaseCount);

INSERT INTO ProductRankingFactors (ProductID, SalesCount30d, ViewCount30d, InStock, StockLevel, IsFeatured, FreshnessScore, FinalRankingScore)
SELECT ProductID, FLOOR(RAND() * 100), FLOOR(RAND() * 2000), IF(Stock > 0, 1, 0), Stock,
       IF(RAND() < 0.1, 1, 0), ROUND(RAND() * 10, 4), ROUND(RAND() * 100, 4)
FROM Products WHERE ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1;

DROP TEMPORARY TABLE IF EXISTS RegionTemplate;
CREATE TEMPORARY TABLE RegionTemplate (rn INT PRIMARY KEY AUTO_INCREMENT, CountryCode CHAR(2), Region VARCHAR(100));
INSERT INTO RegionTemplate (CountryCode, Region) VALUES
    ('MA','Casablanca-Settat'), ('MA','Rabat-Salé-Kénitra'), ('MA','Marrakech-Safi'),
    ('MA','Fès-Meknès'), ('MA','Tanger-Tétouan-Al Hoceïma'), ('MA','Souss-Massa');
SET @region_pool_size = (SELECT COUNT(*) FROM RegionTemplate);

INSERT IGNORE INTO RegionalProductStats (CountryCode, Region, ProductID, ViewCount, PurchaseCount, TrendScore)
SELECT rt.CountryCode, rt.Region, p.ProductID, FLOOR(RAND() * 500), FLOOR(RAND() * 80), ROUND(RAND() * 10, 4)
FROM Products p
JOIN Seq slot ON slot.n < 3
JOIN RegionTemplate rt ON rt.rn = 1 + FLOOR(RAND() * @region_pool_size)
WHERE p.ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1 AND RAND() < 0.6;

INSERT IGNORE INTO IPGeoLocations (IPAddress, CountryCode, Region, City, Latitude, Longitude, ResolvedAt, ExpiresAt)
SELECT
    CONCAT(1 + FLOOR(RAND() * 223), '.', FLOOR(RAND() * 255), '.', FLOOR(RAND() * 255), '.', FLOOR(RAND() * 255)),
    'MA',
    ELT(1 + FLOOR(RAND() * 6), 'Casablanca-Settat','Rabat-Salé-Kénitra','Marrakech-Safi','Fès-Meknès','Tanger-Tétouan-Al Hoceïma','Souss-Massa'),
    ELT(1 + FLOOR(RAND() * 6), 'Casablanca','Rabat','Marrakech','Fès','Tanger','Agadir'),
    ROUND(30 + RAND() * 5, 7), ROUND(-8 + RAND() * 5, 7),
    NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY)
FROM Seq WHERE n < @NB_IPGEO;

DROP TEMPORARY TABLE IF EXISTS GeoPool;
CREATE TEMPORARY TABLE GeoPool (rn INT PRIMARY KEY AUTO_INCREMENT, IPGeoLocationID INT, IPAddress VARCHAR(45));
INSERT INTO GeoPool (IPGeoLocationID, IPAddress) SELECT IPGeoLocationID, IPAddress FROM IPGeoLocations;
SET @geo_pool_size = (SELECT COUNT(*) FROM GeoPool);

DROP TEMPORARY TABLE IF EXISTS SearchTermPool;
CREATE TEMPORARY TABLE SearchTermPool (rn INT PRIMARY KEY AUTO_INCREMENT, DisplayText VARCHAR(255));
INSERT INTO SearchTermPool (DisplayText) SELECT DisplayText FROM SearchDictionary WHERE SourceType = 6;
SET @searchterm_pool_size = (SELECT COUNT(*) FROM SearchTermPool);

DROP TEMPORARY TABLE IF EXISTS CustomerPool;
CREATE TEMPORARY TABLE CustomerPool (rn INT PRIMARY KEY AUTO_INCREMENT, UserID INT, AddressID INT);
INSERT INTO CustomerPool (UserID, AddressID)
SELECT a.UserID, a.AddressID FROM Addresses a INNER JOIN CustomerProfiles cp ON cp.UserID = a.UserID;
SET @customer_pool_size = (SELECT COUNT(*) FROM CustomerPool);

DROP TEMPORARY TABLE IF EXISTS OrderableProductPool;
CREATE TEMPORARY TABLE OrderableProductPool (rn INT PRIMARY KEY AUTO_INCREMENT, ProductID INT, VendorProfileID INT, Price DECIMAL(12,2));
INSERT INTO OrderableProductPool (ProductID, VendorProfileID, Price)
SELECT p.ProductID, vp.VendorProfileID, p.BasePrice
FROM Products p JOIN VendorProfiles vp ON vp.UserID = p.VendorID
WHERE p.Status = 2 AND p.IsActive = 1 AND p.IsBlocked = 0;
SET @orderable_pool_size = (SELECT COUNT(*) FROM OrderableProductPool);



-- =============================================================================
-- 14. CART & WISHLIST
-- =============================================================================
INSERT INTO Carts (UserID)
SELECT UserID FROM Users
WHERE UserID BETWEEN @customer_first_id AND @customer_first_id + @customer_count_actual - 1 AND RAND() < 0.3;
SET @cart_count_actual = ROW_COUNT();
SET @cart_first_id = LAST_INSERT_ID();

INSERT IGNORE INTO CartItems (CartID, ProductID, Quantity, UnitPrice)
SELECT c.CartID, opp.ProductID, 1 + FLOOR(RAND() * 3), opp.Price
FROM Carts c
JOIN Seq slot ON slot.n < 4
JOIN OrderableProductPool opp ON opp.rn = 1 + FLOOR(RAND() * @orderable_pool_size)
WHERE c.CartID BETWEEN @cart_first_id AND @cart_first_id + @cart_count_actual - 1 AND RAND() < 0.5;

INSERT INTO WishLists (UserID, Name, IsDefault)
SELECT UserID, 'My Wishlist', 1
FROM Users
WHERE UserID BETWEEN @customer_first_id AND @customer_first_id + @customer_count_actual - 1 AND RAND() < 0.4;
SET @wishlist_count_actual = ROW_COUNT();
SET @wishlist_first_id = LAST_INSERT_ID();

INSERT IGNORE INTO WishListItems (WishListID, ProductID)
SELECT w.WishListID, opp.ProductID
FROM WishLists w
JOIN Seq slot ON slot.n < 5
JOIN OrderableProductPool opp ON opp.rn = 1 + FLOOR(RAND() * @orderable_pool_size)
WHERE w.WishListID BETWEEN @wishlist_first_id AND @wishlist_first_id + @wishlist_count_actual - 1 AND RAND() < 0.5;


-- =============================================================================
-- 15. ORDERS (+ OrderItems + Payments)
-- =============================================================================
INSERT INTO Orders (UserID, BillingAddressID, ShippingAddressID, OrderStatusID, OrderNumber, OrderedAt, Currency)
SELECT
    cp.UserID, cp.AddressID, cp.AddressID,
    1 + FLOOR(RAND() * 5),
    CONCAT('ORD-', DATE_FORMAT(NOW(), '%Y%m'), '-', LPAD(s.n, 6, '0'), '-', UUID_SHORT()),
    DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 180) DAY),
    'MAD'
FROM Seq s
JOIN CustomerPool cp ON cp.rn = 1 + FLOOR(RAND() * @customer_pool_size)
WHERE s.n < @NB_ORDERS;
SET @order_count_actual = ROW_COUNT();
SET @order_first_id = LAST_INSERT_ID();

INSERT INTO OrderItems (OrderID, ProductID, VendorProfileID, Quantity, UnitPrice, Tax, Total)
SELECT OrderID, ProductID, VendorProfileID, Quantity, Price, 0, ROUND(Price * Quantity, 2)
FROM (
    SELECT o.OrderID, opp.ProductID, opp.VendorProfileID, opp.Price, 1 + FLOOR(RAND() * 3) AS Quantity
    FROM Orders o
    JOIN Seq isq ON isq.n < 20 AND isq.n < 1 + FLOOR(RAND() * @MAX_ITEMS_PER_ORDER)
    JOIN OrderableProductPool opp ON opp.rn = 1 + FLOOR(RAND() * @orderable_pool_size)
    WHERE o.OrderID BETWEEN @order_first_id AND @order_first_id + @order_count_actual - 1
) t;

UPDATE Orders o
JOIN (SELECT OrderID, SUM(Total) AS Subtotal FROM OrderItems GROUP BY OrderID) agg ON agg.OrderID = o.OrderID
SET o.Subtotal = agg.Subtotal,
    o.ShippingFee = ROUND(20 + RAND() * 30, 2),
    o.Tax = ROUND(agg.Subtotal * 0.10, 2),
    o.Total = ROUND(agg.Subtotal * 1.10 + 25, 2)
WHERE o.OrderID BETWEEN @order_first_id AND @order_first_id + @order_count_actual - 1;

INSERT INTO Payments (OrderID, PaymentMethodID, Amount, Currency, TransactionID, Status, PaidAt)
SELECT o.OrderID, 1 + FLOOR(RAND() * 2), o.Total, 'MAD', CONCAT('TXN-', o.OrderID, '-', UUID_SHORT()),
       CASE WHEN o.OrderStatusID IN (3, 4) THEN 1 ELSE 0 END,
       CASE WHEN o.OrderStatusID IN (3, 4) THEN o.OrderedAt ELSE NULL END
FROM Orders o WHERE o.OrderID BETWEEN @order_first_id AND @order_first_id + @order_count_actual - 1;

UPDATE Orders o JOIN Payments pay ON pay.OrderID = o.OrderID
SET o.PaymentID = pay.PaymentID
WHERE o.OrderID BETWEEN @order_first_id AND @order_first_id + @order_count_actual - 1;


-- =============================================================================
-- 16. NOTIFICATIONS (+ NotificationDeliveryLog)
-- =============================================================================
SET @notif_baseline_id = (SELECT IFNULL(MAX(NotificationID), 0) + 1 FROM Notifications);

INSERT INTO Notifications (UserID, NotificationTypeID, Title, Body, RelatedEntityType, RelatedEntityID, IsRead, ReadAt, CreatedAt)
SELECT o.UserID, (SELECT NotificationTypeID FROM NotificationTypes WHERE Code = 'ORDER_CONFIRMED'),
       'Commande confirmée', CONCAT('Votre commande ', o.OrderNumber, ' a été confirmée.'),
       'Order', o.OrderID, IF(RAND() < 0.6, 1, 0), IF(RAND() < 0.6, o.OrderedAt, NULL), o.OrderedAt
FROM Orders o
WHERE o.OrderID BETWEEN @order_first_id AND @order_first_id + @order_count_actual - 1 AND o.OrderStatusID >= 2;

INSERT INTO Notifications (UserID, NotificationTypeID, Title, Body, RelatedEntityType, RelatedEntityID, IsRead, CreatedAt)
SELECT p.VendorID, (SELECT NotificationTypeID FROM NotificationTypes WHERE Code = 'PRODUCT_VALIDATED'),
       'Produit validé', CONCAT('Votre produit ', p.Name, ' a été validé.'),
       'Product', p.ProductID, IF(RAND() < 0.5, 1, 0), p.CreatedAt
FROM Products p
WHERE p.ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1 AND p.Status = 2;

INSERT INTO NotificationDeliveryLog (NotificationID, UserDeviceID, Status, AttemptedAt)
SELECT n.NotificationID, ud.UserDeviceID, IF(RAND() < 0.9, 1, 2), n.CreatedAt
FROM Notifications n JOIN UserDevices ud ON ud.UserID = n.UserID
WHERE n.NotificationID >= @notif_baseline_id;

-- =============================================================================
-- 18. PROMOTIONS  (mirrors SP_CreatePromotionForProduct / SP_CreatePromotionForCategory)
-- =============================================================================
SET @scope_product    = (SELECT ScopeTypeID FROM PromotionScopeTypes WHERE Code = 'PRODUCT');
SET @scope_category    = (SELECT ScopeTypeID FROM PromotionScopeTypes WHERE Code = 'CATEGORY');
SET @discount_pct       = (SELECT DiscountTypeID FROM PromotionDiscountTypes WHERE Code = 'PERCENTAGE');
SET @discount_fixed      = (SELECT DiscountTypeID FROM PromotionDiscountTypes WHERE Code = 'FIXED_AMOUNT');
SET @status_validated     = (SELECT StatusID FROM PromotionStatuses WHERE Code = 'VALIDATED');
SET @status_pending        = (SELECT StatusID FROM PromotionStatuses WHERE Code = 'PENDING');

INSERT INTO Promotions (VendorID, Name, Description, PromoCode, DiscountTypeID, DiscountValue, MaxDiscountAmount, MinOrderAmount, ScopeTypeID, TargetProductID, UsageLimitTotal, UsageLimitPerUser, StartDate, EndDate, StatusID, IsActive)
SELECT
    vp.VendorProfileID, CONCAT('Promo ', p.Name), 'Promotion générée automatiquement.',
    CONCAT('PROMO-', p.ProductID, '-', UUID_SHORT()),
    IF(RAND() < 0.7, @discount_pct, @discount_fixed),
    IF(RAND() < 0.7, ROUND(5 + RAND() * 40, 2), ROUND(20 + RAND() * 200, 2)),
    ROUND(100 + RAND() * 300, 2), ROUND(RAND() * 200, 2),
    @scope_product, p.ProductID,
    100 + FLOOR(RAND() * 400), 1,
    DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 30) DAY),
    DATE_ADD(NOW(), INTERVAL 30 + FLOOR(RAND() * 60) DAY),
    IF(RAND() < 0.8, @status_validated, @status_pending), 1
FROM Products p JOIN VendorProfiles vp ON vp.UserID = p.VendorID
WHERE p.ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1 AND RAND() < 0.15;

INSERT INTO Promotions (VendorID, Name, Description, PromoCode, DiscountTypeID, DiscountValue, MinOrderAmount, ScopeTypeID, TargetCategoryID, UsageLimitPerUser, StartDate, EndDate, StatusID, IsActive)
SELECT
    NULL, CONCAT('Promo catégorie ', c.Name), 'Promotion catégorie générée automatiquement.',
    CONCAT('CATPROMO-', c.CategoryID, '-', UUID_SHORT()),
    @discount_pct, ROUND(5 + RAND() * 25, 2), ROUND(RAND() * 150, 2),
    @scope_category, c.CategoryID, 1,
    DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 15) DAY),
    DATE_ADD(NOW(), INTERVAL 30 + FLOOR(RAND() * 45) DAY),
    @status_validated, 1
FROM Categories c WHERE RAND() < 0.3;


-- =============================================================================
-- CLEANUP + SUMMARY
-- =============================================================================
DROP TEMPORARY TABLE IF EXISTS Seq, BrandPool, CategoryPool, TagPool, VendorPool, BrandModelPool,
    ComboTemplate, ComboCandidates, RegionTemplate, GeoPool, SearchTermPool, CustomerPool,
    OrderableProductPool, EventTypePool;

SET FOREIGN_KEY_CHECKS = 1;

SELECT 'Vendors'              AS Entity, @vendor_count_actual   AS Count
UNION ALL SELECT 'Customers', @customer_count_actual
UNION ALL SELECT 'Admins', @admin_count_actual
UNION ALL SELECT 'Brands', @brand_count_actual
UNION ALL SELECT 'Models', @model_count_actual
UNION ALL SELECT 'Categories', @cat_count_actual
UNION ALL SELECT 'Tags', @tag_count_actual
UNION ALL SELECT 'Products', @product_count_actual
UNION ALL SELECT 'ProductOptionsCombiniason', (SELECT COUNT(*) FROM ProductOptionsCombiniason WHERE ProductID BETWEEN @product_first_id AND @product_first_id + @product_count_actual - 1)
UNION ALL SELECT 'Carts', @cart_count_actual
UNION ALL SELECT 'WishLists', @wishlist_count_actual
UNION ALL SELECT 'Orders', @order_count_actual
UNION ALL SELECT 'OrderItems', (SELECT COUNT(*) FROM OrderItems WHERE OrderID BETWEEN @order_first_id AND @order_first_id + @order_count_actual - 1)
UNION ALL SELECT 'Payments', (SELECT COUNT(*) FROM Payments WHERE OrderID BETWEEN @order_first_id AND @order_first_id + @order_count_actual - 1)
UNION ALL SELECT 'Notifications', (SELECT COUNT(*) FROM Notifications WHERE NotificationID >= @notif_baseline_id)
UNION ALL SELECT 'FAIT_EVENEMENT_CLIENT (this run)', @NB_EVENTS
UNION ALL SELECT 'Promotions (approx)', (SELECT COUNT(*) FROM Promotions);