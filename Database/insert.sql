-- =============================================================================
-- MARKETPLACE PLATFORM — DUMMY DATA SEED SCRIPT
-- =============================================================================

-- Turn off foreign key checks so the order of inserts doesn't cause errors
SET FOREIGN_KEY_CHECKS = 0;

USE marketplace_db;

-- 1. Roles
INSERT IGNORE INTO Roles (RoleID, Name, Code, Description, IsSystem) VALUES
(1, 'Admin', 'ADMIN', 'System administrator', 1),
(2, 'Vendor', 'VENDOR', 'Seller on the platform', 1),
(3, 'Customer', 'CUSTOMER', 'Regular buyer', 1);

-- 2. Countries
INSERT IGNORE INTO Countries (CountryID, Code, Name) VALUES
(1, 'MA', 'Morocco'),
(2, 'US', 'United States'),
(3, 'FR', 'France');

-- 3. Order Status
INSERT IGNORE INTO OrderStatus (OrderStatusID, Name, Code, DisplayOrder) VALUES
(1, 'Pending', 'PENDING', 1),
(2, 'Confirmed', 'CONFIRMED', 2),
(3, 'Shipped', 'SHIPPED', 3),
(4, 'Delivered', 'DELIVERED', 4),
(5, 'Cancelled', 'CANCELLED', 5);

-- 4. Payment Methods
INSERT IGNORE INTO PaymentMethods (PaymentMethodID, Name, Code, WithdrawTax, IsOnline) VALUES
(1, 'Cash on Delivery', 'COD', 0.00, 0),
(2, 'Credit Card', 'CARD', 2.50, 1),
(3, 'PayPal', 'PAYPAL', 3.00, 1);

-- 5. Categories
INSERT IGNORE INTO Categories (CategoryID, Name, Slug, DisplayOrder) VALUES
(1, 'Electronics', 'electronics', 1),
(2, 'Clothing', 'clothing', 2),
(3, 'Home & Garden', 'home-garden', 3);

-- 6. Brands
INSERT IGNORE INTO Brands (BrandID, Name, Slug, CountryID) VALUES
(1, 'TechBrand', 'techbrand', 2),
(2, 'MoroccoStyle', 'moroccostyle', 1);

-- 7. Dummy Users (Note: PasswordHash is just a dummy string here)
INSERT IGNORE INTO Users (UserID, FirstName, LastName, Email, PasswordHash, IsActive, HasPassword) VALUES
(1, 'Admin', 'Super', 'admin@example.com', 'dummyhash123', 1, 1),
(2, 'Vendor', 'Shop', 'vendor@example.com', 'dummyhash123', 1, 1),
(3, 'John', 'Doe', 'customer@example.com', 'dummyhash123', 1, 1);

-- 8. Assign Roles to Users
INSERT IGNORE INTO UserRoles (UserID, RoleID) VALUES
(1, 1), -- Admin gets Admin role
(2, 2), -- Vendor gets Vendor role
(3, 3); -- John gets Customer role

-- Turn foreign key checks back on
SET FOREIGN_KEY_CHECKS = 1;