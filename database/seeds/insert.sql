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
-- ============================================================
-- Script d'insertion des pays (Table: Countries)
-- Colonnes: Code (ISO 3166-1 alpha-2), Name (nom en français)
-- CountryID est en auto_increment, non renseigné ici
-- ============================================================

INSERT INTO Countries (Code, Name) VALUES
('MA', 'Maroc'),
('AF', 'Afghanistan'),
('ZA', 'Afrique du Sud'),
('AL', 'Albanie'),
('DZ', 'Algérie'),
('DE', 'Allemagne'),
('AD', 'Andorre'),
('AO', 'Angola'),
('AI', 'Anguilla'),
('AQ', 'Antarctique'),
('AG', 'Antigua-et-Barbuda'),
('SA', 'Arabie Saoudite'),
('AR', 'Argentine'),
('AM', 'Arménie'),
('AW', 'Aruba'),
('AU', 'Australie'),
('AT', 'Autriche'),
('AZ', 'Azerbaïdjan'),
('BS', 'Bahamas'),
('BH', 'Bahreïn'),
('BD', 'Bangladesh'),
('BB', 'Barbade'),
('BY', 'Biélorussie'),
('BE', 'Belgique'),
('BZ', 'Belize'),
('BJ', 'Bénin'),
('BM', 'Bermudes'),
('BT', 'Bhoutan'),
('BO', 'Bolivie'),
('BA', 'Bosnie-Herzégovine'),
('BW', 'Botswana'),
('BR', 'Brésil'),
('BN', 'Brunei'),
('BG', 'Bulgarie'),
('BF', 'Burkina Faso'),
('BI', 'Burundi'),
('KH', 'Cambodge'),
('CM', 'Cameroun'),
('CA', 'Canada'),
('CV', 'Cap-Vert'),
('CL', 'Chili'),
('CN', 'Chine'),
('CY', 'Chypre'),
('CO', 'Colombie'),
('KM', 'Comores'),
('CG', 'Congo'),
('CD', 'Congo (RDC)'),
('KR', 'Corée du Sud'),
('KP', 'Corée du Nord'),
('CR', 'Costa Rica'),
('CI', 'Côte d''Ivoire'),
('HR', 'Croatie'),
('CU', 'Cuba'),
('CW', 'Curaçao'),
('DK', 'Danemark'),
('DJ', 'Djibouti'),
('DO', 'République Dominicaine'),
('DM', 'Dominique'),
('EG', 'Égypte'),
('AE', 'Émirats Arabes Unis'),
('EC', 'Équateur'),
('ER', 'Érythrée'),
('ES', 'Espagne'),
('EE', 'Estonie'),
('SZ', 'Eswatini'),
('US', 'États-Unis'),
('ET', 'Éthiopie'),
('FJ', 'Fidji'),
('FI', 'Finlande'),
('FR', 'France'),
('GA', 'Gabon'),
('GM', 'Gambie'),
('GE', 'Géorgie'),
('GH', 'Ghana'),
('GI', 'Gibraltar'),
('GR', 'Grèce'),
('GD', 'Grenade'),
('GL', 'Groenland'),
('GP', 'Guadeloupe'),
('GU', 'Guam'),
('GT', 'Guatemala'),
('GG', 'Guernesey'),
('GN', 'Guinée'),
('GQ', 'Guinée Équatoriale'),
('GW', 'Guinée-Bissau'),
('GY', 'Guyana'),
('GF', 'Guyane Française'),
('HT', 'Haïti'),
('HN', 'Honduras'),
('HK', 'Hong Kong'),
('HU', 'Hongrie'),
('IM', 'Île de Man'),
('AX', 'Îles Åland'),
('KY', 'Îles Caïmans'),
('CK', 'Îles Cook'),
('FO', 'Îles Féroé'),
('FK', 'Îles Malouines'),
('MP', 'Îles Mariannes du Nord'),
('MH', 'Îles Marshall'),
('SB', 'Îles Salomon'),
('TC', 'Îles Turques-et-Caïques'),
('VG', 'Îles Vierges Britanniques'),
('VI', 'Îles Vierges des États-Unis'),
('IN', 'Inde'),
('ID', 'Indonésie'),
('IQ', 'Irak'),
('IR', 'Iran'),
('IE', 'Irlande'),
('IS', 'Islande'),
('IT', 'Italie'),
('JM', 'Jamaïque'),
('JP', 'Japon'),
('JE', 'Jersey'),
('JO', 'Jordanie'),
('KZ', 'Kazakhstan'),
('KE', 'Kenya'),
('KG', 'Kirghizistan'),
('KI', 'Kiribati'),
('XK', 'Kosovo'),
('KW', 'Koweït'),
('LA', 'Laos'),
('LS', 'Lesotho'),
('LV', 'Lettonie'),
('LB', 'Liban'),
('LR', 'Libéria'),
('LY', 'Libye'),
('LI', 'Liechtenstein'),
('LT', 'Lituanie'),
('LU', 'Luxembourg'),
('MO', 'Macao'),
('MK', 'Macédoine du Nord'),
('MG', 'Madagascar'),
('MY', 'Malaisie'),
('MW', 'Malawi'),
('MV', 'Maldives'),
('ML', 'Mali'),
('MT', 'Malte'),
('MQ', 'Martinique'),
('MU', 'Maurice'),
('MR', 'Mauritanie'),
('YT', 'Mayotte'),
('MX', 'Mexique'),
('FM', 'Micronésie'),
('MD', 'Moldavie'),
('MC', 'Monaco'),
('MN', 'Mongolie'),
('ME', 'Monténégro'),
('MS', 'Montserrat'),
('MZ', 'Mozambique'),
('MM', 'Myanmar'),
('NA', 'Namibie'),
('NR', 'Nauru'),
('NP', 'Népal'),
('NI', 'Nicaragua'),
('NE', 'Niger'),
('NG', 'Nigéria'),
('NU', 'Niue'),
('NO', 'Norvège'),
('NC', 'Nouvelle-Calédonie'),
('NZ', 'Nouvelle-Zélande'),
('OM', 'Oman'),
('UG', 'Ouganda'),
('UZ', 'Ouzbékistan'),
('PK', 'Pakistan'),
('PW', 'Palaos'),
('PS', 'Palestine'),
('PA', 'Panama'),
('PG', 'Papouasie-Nouvelle-Guinée'),
('PY', 'Paraguay'),
('NL', 'Pays-Bas'),
('PE', 'Pérou'),
('PH', 'Philippines'),
('PN', 'Pitcairn'),
('PL', 'Pologne'),
('PF', 'Polynésie Française'),
('PR', 'Porto Rico'),
('PT', 'Portugal'),
('QA', 'Qatar'),
('RE', 'Réunion'),
('RO', 'Roumanie'),
('GB', 'Royaume-Uni'),
('RU', 'Russie'),
('RW', 'Rwanda'),
('EH', 'Sahara Occidental'),
('BL', 'Saint-Barthélemy'),
('KN', 'Saint-Kitts-et-Nevis'),
('SM', 'Saint-Marin'),
('MF', 'Saint-Martin'),
('PM', 'Saint-Pierre-et-Miquelon'),
('VC', 'Saint-Vincent-et-les-Grenadines'),
('SH', 'Sainte-Hélène'),
('LC', 'Sainte-Lucie'),
('SV', 'Salvador'),
('WS', 'Samoa'),
('AS', 'Samoa Américaines'),
('ST', 'Sao Tomé-et-Principe'),
('SN', 'Sénégal'),
('RS', 'Serbie'),
('SC', 'Seychelles'),
('SL', 'Sierra Leone'),
('SG', 'Singapour'),
('SX', 'Sint Maarten'),
('SK', 'Slovaquie'),
('SI', 'Slovénie'),
('SO', 'Somalie'),
('SD', 'Soudan'),
('SS', 'Soudan du Sud'),
('LK', 'Sri Lanka'),
('SE', 'Suède'),
('CH', 'Suisse'),
('SR', 'Suriname'),
('SY', 'Syrie'),
('TJ', 'Tadjikistan'),
('TW', 'Taïwan'),
('TZ', 'Tanzanie'),
('TD', 'Tchad'),
('CZ', 'Tchéquie'),
('TF', 'Terres Australes Françaises'),
('TH', 'Thaïlande'),
('TL', 'Timor Oriental'),
('TG', 'Togo'),
('TK', 'Tokelau'),
('TO', 'Tonga'),
('TT', 'Trinité-et-Tobago'),
('TN', 'Tunisie'),
('TM', 'Turkménistan'),
('TR', 'Turquie'),
('TV', 'Tuvalu'),
('UA', 'Ukraine'),
('UY', 'Uruguay'),
('VU', 'Vanuatu'),
('VA', 'Vatican'),
('VE', 'Venezuela'),
('VN', 'Vietnam'),
('WF', 'Wallis-et-Futuna'),
('YE', 'Yémen'),
('ZM', 'Zambie'),
('ZW', 'Zimbabwe');

-- 3. Order Status
INSERT IGNORE INTO OrderStatus (OrderStatusID, Name, Code, DisplayOrder) VALUES
(1, 'Pending', 'PENDING', 1),
(2, 'Confirmed', 'CONFIRMED', 2),
(3, 'Shipped', 'SHIPPED', 3),
(4, 'Delivered', 'DELIVERED', 4),
(5, 'Cancelled', 'CANCELLED', 5);

-- 4. Payment Methods
-- 1. Le client paie directement lors de la commande (En ligne)
INSERT IGNORE INTO PaymentMethods (PaymentMethodID, Name, Code, WithdrawTax, IsOnline) 
VALUES (1, 'Paiement sur la plateforme', 'PLATFORM', 2.50, 1);

-- 2. Le client paie à la réception du colis (Hors ligne)
INSERT IGNORE INTO PaymentMethods (PaymentMethodID, Name, Code, WithdrawTax, IsOnline) 
VALUES (2, 'Paiement à la livraison', 'DELIVERY', 0.00, 0);
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
INSERT INTO ResourcesRoles (Label) 
VALUES 
    ('Pour Administrateur'),
    ('Pour Visiteur');
    -- Type de ressource pour les documents PDF
INSERT INTO ResourcesTypes (Name) VALUES ('Pdf');

-- Type de ressource pour les fichiers vidéo
INSERT INTO ResourcesTypes (Name) VALUES ('Video');

-- Type de ressource pour les images et photos
INSERT INTO ResourcesTypes (Name) VALUES ('Images');

-- Type de ressource pour les fichiers de données JSON
INSERT INTO ResourcesTypes (Name) VALUES ('Json');



INSERT INTO ProductStatus (Code, Libelle) VALUES
('draft', 'Brouillon'),
('validated', 'Validé'),
('Refused', 'refusé'),
('blocked', 'Bloqué');
-- Turn foreign key checks back on
SET FOREIGN_KEY_CHECKS = 1;

