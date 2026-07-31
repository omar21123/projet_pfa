-- =============================================================================
-- CLEANUP SCRIPT — deletes everything the "FULL RANDOM DEV/TEST DATA
-- GENERATOR" script inserts, so it can be safely re-run from a clean slate.
--
-- Excluded on purpose (these are lookup/reference tables, not generated
-- per-run data — deleting them would break the generator's own FK lookups):
--   Countries, Roles, PaymentMethods, OrderStatus, Units, ResourcesTypes,
--   ResourcesRoles, ProductStatus, PromotionDiscountTypes,
--   PromotionScopeTypes, PromotionStatuses, NotificationTypes,
--   DIM_TYPE_EVENEMENT
--
-- Also left alone: ProductsConfigAttribute / ConfigAttributeOptions
-- (Couleur/Taille + their options) — these are inserted with INSERT IGNORE
-- on fixed values in the generator, so re-running it is a no-op against
-- them anyway. Uncomment the block near the bottom if you want them gone too.
--
-- FK checks are disabled for the duration so table order doesn't matter,
-- then re-enabled at the end. Run this whole file in one go.
-- =============================================================================

USE marketplace_db;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES = 0;   -- Workbench "safe updates" blocks DELETE/UPDATE with no WHERE on a key column

-- ---------------------------------------------------------------------------
-- Recommendation engine
-- ---------------------------------------------------------------------------
DELETE FROM FAIT_SCORE_CLIENT_PRODUIT;
DELETE FROM FAIT_EVENEMENT_CLIENT;

-- ---------------------------------------------------------------------------
-- Notifications
-- ---------------------------------------------------------------------------
DELETE FROM NotificationDeliveryLog;
DELETE FROM Notifications;
DELETE FROM UserNotificationPreferences;

-- ---------------------------------------------------------------------------
-- Orders
-- ---------------------------------------------------------------------------
DELETE FROM Payments;
DELETE FROM OrderItems;
DELETE FROM Orders;

-- ---------------------------------------------------------------------------
-- Cart / Wishlist
-- ---------------------------------------------------------------------------
DELETE FROM CartItems;
DELETE FROM Carts;
DELETE FROM WishListItems;
DELETE FROM WishLists;

-- ---------------------------------------------------------------------------
-- Promotions
-- ---------------------------------------------------------------------------
DELETE FROM Promotions;

-- ---------------------------------------------------------------------------
-- Search analytics
-- ---------------------------------------------------------------------------
DELETE FROM UserSearchHistory;
DELETE FROM IPGeoLocations;
DELETE FROM RegionalProductStats;
DELETE FROM ProductRankingFactors;
DELETE FROM SearchTermProductStats;
DELETE FROM SearchSynonyms;

-- ---------------------------------------------------------------------------
-- Product variants
-- ---------------------------------------------------------------------------
DELETE FROM ProductOptionsCombiniasonDetails;
DELETE FROM ProductOptionsCombiniason;

-- ---------------------------------------------------------------------------
-- Products
-- ---------------------------------------------------------------------------
DELETE FROM ProductTags;
DELETE FROM ProductDetails;
DELETE FROM ProductAllowedPayements;
DELETE FROM ProductSearchIndex;
DELETE FROM ProductResources;
DELETE FROM ProductCategories;
DELETE FROM Products;

-- ---------------------------------------------------------------------------
-- Search dictionary (rebuilt entirely by the generator's ON DUPLICATE KEY
-- UPDATE upserts, so it's safe to wipe)
-- ---------------------------------------------------------------------------
DELETE FROM SearchDictionary;

-- ---------------------------------------------------------------------------
-- Catalog
-- ---------------------------------------------------------------------------
DELETE FROM Tags;
DELETE FROM CategoryClosure;
DELETE FROM Categories;
DELETE FROM Models;
DELETE FROM Brands;

-- Uncomment if you also want Couleur/Taille + their options wiped
-- (not necessary — the generator re-creates them with INSERT IGNORE):
-- DELETE FROM ConfigAttributeOptions;
-- DELETE FROM ProductsConfigAttribute;

-- ---------------------------------------------------------------------------
-- Vendor finance
-- ---------------------------------------------------------------------------
DELETE FROM WithdrawHistory;
DELETE FROM BankAccounts;
DELETE FROM PaymentInformations;

-- ---------------------------------------------------------------------------
-- Users / Auth
-- ---------------------------------------------------------------------------
DELETE FROM Addresses;
DELETE FROM UserDevices;
DELETE FROM UserRefreshTokens;
DELETE FROM UserExternalLogins;
DELETE FROM AdminProfiles;
DELETE FROM CustomerProfiles;
DELETE FROM VendorProfiles;
DELETE FROM UserRoles;
DELETE FROM Users;

SET FOREIGN_KEY_CHECKS = 1;
SET SQL_SAFE_UPDATES = 1;

-- ---------------------------------------------------------------------------
-- Optional: reset AUTO_INCREMENT counters back to 1 so IDs look clean on
-- the next run. Safe to skip if you don't care about ID numbering.
-- ---------------------------------------------------------------------------
-- ALTER TABLE Users AUTO_INCREMENT = 1;
-- ALTER TABLE VendorProfiles AUTO_INCREMENT = 1;
-- ALTER TABLE CustomerProfiles AUTO_INCREMENT = 1;
-- ALTER TABLE AdminProfiles AUTO_INCREMENT = 1;
-- ALTER TABLE Addresses AUTO_INCREMENT = 1;
-- ALTER TABLE BankAccounts AUTO_INCREMENT = 1;
-- ALTER TABLE WithdrawHistory AUTO_INCREMENT = 1;
-- ALTER TABLE PaymentInformations AUTO_INCREMENT = 1;
-- ALTER TABLE Brands AUTO_INCREMENT = 1;
-- ALTER TABLE Models AUTO_INCREMENT = 1;
-- ALTER TABLE Categories AUTO_INCREMENT = 1;
-- ALTER TABLE Tags AUTO_INCREMENT = 1;
-- ALTER TABLE Products AUTO_INCREMENT = 1;
-- ALTER TABLE ProductOptionsCombiniason AUTO_INCREMENT = 1;
-- ALTER TABLE Carts AUTO_INCREMENT = 1;
-- ALTER TABLE WishLists AUTO_INCREMENT = 1;
-- ALTER TABLE Orders AUTO_INCREMENT = 1;
-- ALTER TABLE OrderItems AUTO_INCREMENT = 1;
-- ALTER TABLE Payments AUTO_INCREMENT = 1;
-- ALTER TABLE Notifications AUTO_INCREMENT = 1;
-- ALTER TABLE Promotions AUTO_INCREMENT = 1;

SELECT 'Cleanup complete' AS Status;