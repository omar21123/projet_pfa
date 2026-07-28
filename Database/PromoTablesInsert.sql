CREATE TABLE PromotionDiscountTypes (
    DiscountTypeID  INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    Code            VARCHAR(30)     NOT NULL,
    Label           VARCHAR(100)    NOT NULL,
    IsActive        BIT(1)          NOT NULL DEFAULT b'1',

    PRIMARY KEY (DiscountTypeID),
    UNIQUE KEY UQ_PromotionDiscountTypes_Code (Code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO PromotionDiscountTypes (Code, Label) VALUES
    ('PERCENTAGE', 'Pourcentage'),
    ('FIXED_AMOUNT', 'Montant fixe');
    CREATE TABLE PromotionScopeTypes (
    ScopeTypeID     INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    Code            VARCHAR(30)     NOT NULL,
    Label           VARCHAR(100)    NOT NULL,
    IsActive        BIT(1)          NOT NULL DEFAULT b'1',

    PRIMARY KEY (ScopeTypeID),
    UNIQUE KEY UQ_PromotionScopeTypes_Code (Code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO PromotionScopeTypes (Code, Label) VALUES
    ('PRODUCT', 'Produit specifique'),
    ('CATEGORY', 'Categorie'),
    ('CATALOG', 'Tout le catalogue vendeur');
    CREATE TABLE PromotionStatuses (
    StatusID        INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    Code            VARCHAR(30)     NOT NULL,
    Label           VARCHAR(100)    NOT NULL,
    IsActive        BIT(1)          NOT NULL DEFAULT b'1',

    PRIMARY KEY (StatusID),
    UNIQUE KEY UQ_PromotionStatuses_Code (Code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO PromotionStatuses (Code, Label) VALUES
    ('PENDING', 'En attente'),
    ('VALIDATED', 'Validee'),
    ('REFUSED', 'Refusee'),
    ('EXPIRED', 'Expiree'),
    ('BLOCKED', 'Bloquee');
CREATE TABLE Promotions (
    PromotionID         INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    VendorID             INT            NOT NULL,
    Name                 VARCHAR(150)   NOT NULL,
    Description           VARCHAR(500)   NULL,
    PromoCode             VARCHAR(50)    NULL,
    DiscountTypeID         INT UNSIGNED   NOT NULL,
    DiscountValue           DECIMAL(10,2)  NOT NULL,
    MaxDiscountAmount        DECIMAL(10,2)  NULL,
    MinOrderAmount             DECIMAL(10,2)  NULL,
    ScopeTypeID                 INT UNSIGNED   NOT NULL,
    TargetProductID               INT            NULL,
    TargetCategoryID                INT            NULL,
    UsageLimitTotal                    INT UNSIGNED   NULL,
    UsageLimitPerUser                     INT UNSIGNED   NULL DEFAULT 1,
    UsageCount                               INT UNSIGNED   NOT NULL DEFAULT 0,
    StartDate                                 DATETIME       NOT NULL,
    EndDate                                    DATETIME       NOT NULL,
    StatusID                                    INT UNSIGNED   NOT NULL,
    IsActive                                     BIT(1)         NOT NULL DEFAULT b'1',
    CreatedAt                                     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt                                      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (PromotionID),
    UNIQUE KEY UQ_Promotions_PromoCode (PromoCode),
    KEY IX_Promotions_VendorID (VendorID),
    KEY IX_Promotions_IsActive (IsActive),
    KEY IX_Promotions_TargetProduct (ScopeTypeID, TargetProductID),
    KEY IX_Promotions_TargetCategory (ScopeTypeID, TargetCategoryID),
    KEY IX_Promotions_DateRange (StartDate, EndDate),
    KEY IX_Promotions_StatusID (StatusID),

    CONSTRAINT FK_Promotions_VendorProfiles
        FOREIGN KEY (VendorID) REFERENCES VendorProfiles (VendorProfileID)
        ON DELETE CASCADE,

    CONSTRAINT FK_Promotions_DiscountType
        FOREIGN KEY (DiscountTypeID) REFERENCES PromotionDiscountTypes (DiscountTypeID)
        ON DELETE RESTRICT,

    CONSTRAINT FK_Promotions_ScopeType
        FOREIGN KEY (ScopeTypeID) REFERENCES PromotionScopeTypes (ScopeTypeID)
        ON DELETE RESTRICT,

    CONSTRAINT FK_Promotions_Status
        FOREIGN KEY (StatusID) REFERENCES PromotionStatuses (StatusID)
        ON DELETE RESTRICT,

    CONSTRAINT FK_Promotions_TargetProduct
        FOREIGN KEY (TargetProductID) REFERENCES Products (ProductID)
        ON DELETE CASCADE,

    CONSTRAINT FK_Promotions_TargetCategory
        FOREIGN KEY (TargetCategoryID) REFERENCES Categories (CategoryID)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE Promotions
ADD COLUMN DeletedAt DATETIME NULL AFTER UpdatedAt;

CREATE INDEX IX_Promotions_DeletedAt ON Promotions (DeletedAt);