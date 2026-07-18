DELIMITER $$

DROP PROCEDURE IF EXISTS SP_CreateProductResource $$

CREATE PROCEDURE SP_CreateProductResource (
    IN  p_ProductID      INT,
    IN  p_ResourceType   VARCHAR(100),   -- ex: 'Video', 'Image', 'Document'...
    IN  p_ResourceRole   INT,
    IN  p_ResourcePath   VARCHAR(500),
    OUT p_ResourceID     INT,
    OUT p_Success        TINYINT,
    OUT p_Message        VARCHAR(255)
)
BEGIN
    DECLARE v_ResourcesTypeID INT DEFAULT NULL;
    DECLARE v_RoleExists      INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_Success = 0;
        SET p_ResourceID = NULL;
        IF p_Message IS NULL OR p_Message = '' THEN
            SET p_Message = 'Une erreur est survenue lors de l''ajout de la ressource.';
        END IF;
    END;

    -- 1) Resolve ResourcesTypeID from name (case-insensitive)
    SELECT ID INTO v_ResourcesTypeID
    FROM ResourcesTypes
    WHERE LOWER(Name) = LOWER(p_ResourceType)
    LIMIT 1;

    IF v_ResourcesTypeID IS NULL THEN
        SET p_Message = 'Type de ressource invalide.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid ResourceType: type not found in ResourcesTypes';
    END IF;

    -- 2) Check ResourceRole exists
    SELECT COUNT(*) INTO v_RoleExists
    FROM ResourcesRoles
    WHERE RoleID = p_ResourceRole;

    IF v_RoleExists = 0 THEN
        SET p_Message = 'Rôle de ressource invalide.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid ResourceRole: role not found in ResourcesRoles';
    END IF;

    -- 3) Insert
    START TRANSACTION;

    INSERT INTO ProductResources (
        ProductID,
        ResourcesPath,
        ResourcesTypeID,
        ResourceRoleID
    )
    VALUES (
        p_ProductID,
        p_ResourcePath,
        v_ResourcesTypeID,
        p_ResourceRole
    );

    SET p_ResourceID = LAST_INSERT_ID();
    SET p_Success = 1;
    SET p_Message = 'Ressource ajoutée avec succès.';

    COMMIT;
END $$

DELIMITER ;
DELIMITER $$
DROP PROCEDURE IF EXISTS SP_CreateProduct $$
CREATE PROCEDURE SP_CreateProduct (
    IN p_VendorID     INT,
    IN p_BrandID      INT,
    IN p_ModelID      INT,
    IN p_Name         VARCHAR(255),
    IN p_Barcode      VARCHAR(100),
    IN p_Description  TEXT,
    IN p_BasePrice    DECIMAL(12,2),
    IN p_Stock        INT,
    OUT p_ProductID   INT,
    OUT p_Success     TINYINT,
    OUT p_Message     VARCHAR(255)
)
BEGIN
    DECLARE v_BrandName VARCHAR(150) DEFAULT NULL;
    DECLARE v_ModelName VARCHAR(150) DEFAULT NULL;
    DECLARE v_SearchText TEXT;
    DECLARE v_NormalizedName VARCHAR(255);
    DECLARE v_DisplayBrandName VARCHAR(255);
    DECLARE v_NormalizedBrandName VARCHAR(255);
    DECLARE v_DisplayBrandModelName VARCHAR(255);
    DECLARE v_NormalizedBrandModelName VARCHAR(255);
    DECLARE v_DisplayModelName VARCHAR(255);
    DECLARE v_NormalizedModelName VARCHAR(255);
    DECLARE v_ExistingCount INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_Success = 0;
        SET p_ProductID = NULL;
        SET p_Message = 'Une erreur est survenue lors de la création du produit.';
    END;

    -- Barcode uniqueness check (UNI key will also enforce it, but this gives a clean French message)
    IF p_Barcode IS NOT NULL AND EXISTS (
        SELECT 1 FROM Products WHERE Barcode = p_Barcode AND DeletedAt IS NULL
    ) THEN
        SET p_Success = 0;
        SET p_ProductID = NULL;
        SET p_Message = 'Ce code-barres est déjà utilisé par un autre produit.';
    ELSE
        START TRANSACTION;

        INSERT INTO Products (
            VendorID,
            BrandID,
            ModelID,
            Name,
            Barcode,
            Description,
            BasePrice,
            Stock,
            Status,
            CreatedAt,
            UpdatedAt,
            DeletedAt,
            IsActive,
            RefuseNotes,
            RefusedBy,
            RefuseAt,
            RefuseAttempt,
            ValidatorID,
            ValidationNotes,
            ValidationDate,
            IsBlocked,
            BlokedBy,
            BlockedDate,
            BlockedNotes
        )
        VALUES (
            p_VendorID,
            p_BrandID,
            p_ModelID,
            p_Name,
            p_Barcode,
            p_Description,
            IFNULL(p_BasePrice, 0.00),
            IFNULL(p_Stock, 0),
            1,                  -- Status: default
            CURRENT_TIMESTAMP,  -- CreatedAt
            CURRENT_TIMESTAMP,  -- UpdatedAt
            NULL,               -- DeletedAt
            1,                  -- IsActive: default
            NULL,               -- RefuseNotes
            NULL,               -- RefusedBy
            NULL,               -- RefuseAt
            1,                  -- RefuseAttempt: default
            NULL,               -- ValidatorID
            NULL,               -- ValidationNotes
            NULL,               -- ValidationDate
            0,                  -- IsBlocked: default
            NULL,               -- BlokedBy
            NULL,               -- BlockedDate
            NULL                -- BlockedNotes
        );

        SET p_ProductID = LAST_INSERT_ID();

        -- Look up names needed for the composite search entries / search index text
        IF p_BrandID IS NOT NULL THEN
            SELECT Name INTO v_BrandName FROM Brands WHERE BrandID = p_BrandID;
        END IF;

        IF p_ModelID IS NOT NULL THEN
            SELECT Name INTO v_ModelName FROM Models WHERE ModelID = p_ModelID;
        END IF;

        -- ============================================================
        -- ProductSearchIndex: one row per product, "Brand Model Name"
        -- text, gracefully skipping whichever part is NULL
        -- ============================================================
        SET v_SearchText = CONCAT_WS(' ', v_BrandName, v_ModelName, p_Name);

        INSERT INTO ProductSearchIndex (ProductID, SearchText)
        VALUES (p_ProductID, v_SearchText);

        -- ============================================================
        -- SearchDictionary entries (Name / Brand+Name / Brand+Model+Name / Model+Name)
        -- ============================================================

        -- Entry 1: Name alone (always)
        SET v_NormalizedName = LOWER(TRIM(p_Name));

        SELECT COUNT(*) INTO v_ExistingCount
        FROM SearchDictionary
        WHERE NormalizedText = v_NormalizedName;

        IF v_ExistingCount > 0 THEN
            UPDATE SearchDictionary
            SET DisplayText = p_Name, SourceType = 6, SourceID = p_ProductID, IsActive = 1, UpdatedAt = NOW()
            WHERE NormalizedText = v_NormalizedName;
        ELSE
            INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
            VALUES (p_Name, v_NormalizedName, 6, p_ProductID);
        END IF;

        -- Entry 2: BrandName + Name (only when a brand was given)
        IF p_BrandID IS NOT NULL AND v_BrandName IS NOT NULL THEN
            SET v_DisplayBrandName = CONCAT(v_BrandName, ' ', p_Name);
            SET v_NormalizedBrandName = LOWER(TRIM(v_DisplayBrandName));

            SET v_ExistingCount = 0;
            SELECT COUNT(*) INTO v_ExistingCount
            FROM SearchDictionary
            WHERE NormalizedText = v_NormalizedBrandName;

            IF v_ExistingCount > 0 THEN
                UPDATE SearchDictionary
                SET DisplayText = v_DisplayBrandName, SourceType = 6, SourceID = p_ProductID, IsActive = 1, UpdatedAt = NOW()
                WHERE NormalizedText = v_NormalizedBrandName;
            ELSE
                INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
                VALUES (v_DisplayBrandName, v_NormalizedBrandName, 6, p_ProductID);
            END IF;
        END IF;

        -- Entry 3: BrandName + ModelName + Name (only when both a brand and a model were given)
        IF p_BrandID IS NOT NULL AND v_BrandName IS NOT NULL
           AND p_ModelID IS NOT NULL AND v_ModelName IS NOT NULL THEN
            SET v_DisplayBrandModelName = CONCAT(v_BrandName, ' ', v_ModelName, ' ', p_Name);
            SET v_NormalizedBrandModelName = LOWER(TRIM(v_DisplayBrandModelName));

            SET v_ExistingCount = 0;
            SELECT COUNT(*) INTO v_ExistingCount
            FROM SearchDictionary
            WHERE NormalizedText = v_NormalizedBrandModelName;

            IF v_ExistingCount > 0 THEN
                UPDATE SearchDictionary
                SET DisplayText = v_DisplayBrandModelName, SourceType = 6, SourceID = p_ProductID, IsActive = 1, UpdatedAt = NOW()
                WHERE NormalizedText = v_NormalizedBrandModelName;
            ELSE
                INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
                VALUES (v_DisplayBrandModelName, v_NormalizedBrandModelName, 6, p_ProductID);
            END IF;
        END IF;

        -- Entry 4: ModelName + Name (only when a model was given)
        IF p_ModelID IS NOT NULL AND v_ModelName IS NOT NULL THEN
            SET v_DisplayModelName = CONCAT(v_ModelName, ' ', p_Name);
            SET v_NormalizedModelName = LOWER(TRIM(v_DisplayModelName));

            SET v_ExistingCount = 0;
            SELECT COUNT(*) INTO v_ExistingCount
            FROM SearchDictionary
            WHERE NormalizedText = v_NormalizedModelName;

            IF v_ExistingCount > 0 THEN
                UPDATE SearchDictionary
                SET DisplayText = v_DisplayModelName, SourceType = 6, SourceID = p_ProductID, IsActive = 1, UpdatedAt = NOW()
                WHERE NormalizedText = v_NormalizedModelName;
            ELSE
                INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
                VALUES (v_DisplayModelName, v_NormalizedModelName, 6, p_ProductID);
            END IF;
        END IF;

        SET p_Success = 1;
        SET p_Message = 'Produit créé avec succès.';
        COMMIT;
    END IF;
END $$
DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS SP_CreateProductCategory $$

CREATE PROCEDURE SP_CreateProductCategory (
    IN  p_ProductID  INT,
    IN  p_CategoryID INT,
    OUT p_Success    TINYINT,
    OUT p_Message    VARCHAR(255)
)
BEGIN
    DECLARE v_CategoryExists   INT DEFAULT 0;
    DECLARE v_ParentCategoryID INT DEFAULT NULL;
    DECLARE v_IsPrimary        TINYINT DEFAULT 0;
    DECLARE v_Slug             VARCHAR(255) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_Success = 0;
        IF p_Message IS NULL OR p_Message = '' THEN
            SET p_Message = 'Une erreur est survenue lors de l''association de la catégorie.';
        END IF;
    END;

    -- 1) Check category exists
    SELECT COUNT(*) INTO v_CategoryExists
    FROM Categories
    WHERE CategoryID = p_CategoryID;

    IF v_CategoryExists = 0 THEN
        SET p_Message = 'Catégorie introuvable.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid CategoryID: category not found';
    END IF;

    -- 2) Determine IsPrimary based on ParentCategoryID
    SELECT ParentCategoryID INTO v_ParentCategoryID
    FROM Categories
    WHERE CategoryID = p_CategoryID;

    IF v_ParentCategoryID IS NULL THEN
        SET v_IsPrimary = 1;
    ELSE
        SET v_IsPrimary = 0;
    END IF;

    START TRANSACTION;

    -- 3) Insert product-category link
    INSERT INTO ProductCategories (
        ProductID,
        CategoryID,
        IsPrimary
    )
    VALUES (
        p_ProductID,
        p_CategoryID,
        v_IsPrimary
    );

    -- 4) Get category slug
    SELECT Slug INTO v_Slug
    FROM Categories
    WHERE CategoryID = p_CategoryID;

    -- 5) Append slug to search index
    UPDATE ProductSearchIndex
    SET SearchText = CONCAT(SearchText, ' ', v_Slug)
    WHERE ProductID = p_ProductID;

    SET p_Success = 1;
    SET p_Message = 'Catégorie associée avec succès.';

    COMMIT;
END $$

DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS SP_GetOrCreateProductsConfigAttributeByName $$

CREATE PROCEDURE SP_GetOrCreateProductsConfigAttributeByName (
    IN  p_ConfigName  VARCHAR(150),
    OUT p_AttributeID INT,
    OUT p_Success     TINYINT,
    OUT p_Message     VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_Success = 0;
        SET p_AttributeID = NULL;
        SET p_Message = 'Une erreur est survenue lors de la récupération de l''attribut.';
    END;

    -- 1) Try to find existing attribute
    SELECT AttributeID INTO p_AttributeID
    FROM ProductsConfigAttribute
    WHERE Name = p_ConfigName
    LIMIT 1;

    IF p_AttributeID IS NOT NULL THEN
        -- 2) Already exists
        SET p_Success = 1;
        SET p_Message = 'Attribut existant récupéré avec succès.';
    ELSE
        -- 3) Doesn't exist -> create it via the other SP
        CALL SP_CreateProductsConfigAttributeByName(p_ConfigName, p_AttributeID);

        SET p_Success = 1;
        SET p_Message = 'Attribut créé avec succès.';
    END IF;

    -- Final result set (in addition to OUT params)
    SELECT p_AttributeID AS AttributeID, p_Success AS Success, p_Message AS Message;
END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS SP_CreateProductDetailByOptionName $$

CREATE PROCEDURE SP_CreateProductDetailByOptionName (
    IN  p_ProductID  INT,
    IN  p_ConfigID   INT,            -- ProductsConfigAttributeID
    IN  p_Name       VARCHAR(150),   -- Option label/value
    IN  p_IsDefault  TINYINT,
    OUT p_DetailID   INT,
    OUT p_OptionID   INT,
    OUT p_Success    TINYINT,
    OUT p_Message    VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_Success = 0;
        SET p_DetailID = NULL;
        IF p_Message IS NULL OR p_Message = '' THEN
            SET p_Message = 'Une erreur est survenue lors de l''ajout du détail produit.';
        END IF;
    END;

    -- 1) Try to find existing option by name (case-insensitive)
    SELECT OptionID INTO p_OptionID
    FROM ConfigAttributeOptions
    WHERE LOWER(OptionValue) = LOWER(p_Name)
      AND ProductsConfigAttributeID = p_ConfigID
    LIMIT 1;

    IF p_OptionID IS NULL THEN
        -- 2) Doesn't exist -> create it via the other SP
        CALL SP_CreateConfigAttributeOptionByName(p_ConfigID, p_Name, p_OptionID);
    END IF;

    START TRANSACTION;

    -- 3) If this option should be default, unset other defaults for this attribute first
    IF p_IsDefault = 1 THEN
        UPDATE ConfigAttributeOptions
        SET IsDefaultForAttribute = 0
        WHERE ProductsConfigAttributeID = p_ConfigID;

        UPDATE ConfigAttributeOptions
        SET IsDefaultForAttribute = 1
        WHERE OptionID = p_OptionID;
    END IF;

    -- 4) Insert into ProductDetails (CustomValue ignored per instructions)
    INSERT INTO ProductDetails (
        ProductID,
        ProductsConfigAttributeID,
        OptionID
    )
    VALUES (
        p_ProductID,
        p_ConfigID,
        p_OptionID
    );

    SET p_DetailID = LAST_INSERT_ID();
    SET p_Success = 1;
    SET p_Message = 'Détail produit ajouté avec succès.';

    COMMIT;
END $$

DELIMITER ;
DELIMITER $$

DROP PROCEDURE IF EXISTS SP_AddProductTagByName $$

CREATE PROCEDURE SP_AddProductTagByName (
    IN  p_ProductID INT,
    IN  p_TagName   VARCHAR(100),
    OUT p_TagID     INT,
    OUT p_Success   TINYINT,
    OUT p_Message   VARCHAR(255)
)
BEGIN
    DECLARE v_AlreadyLinked INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_Success = 0;
        SET p_TagID = NULL;
        IF p_Message IS NULL OR p_Message = '' THEN
            SET p_Message = 'Une erreur est survenue lors de l''ajout du tag.';
        END IF;
    END;

    -- 1) Try to find existing tag by name
    SELECT TagID INTO p_TagID
    FROM Tags
    WHERE Name = p_TagName
    LIMIT 1;

    IF p_TagID IS NULL THEN
        -- 2) Doesn't exist -> create it via the other SP
        CALL SP_CreateTagByName(p_TagName, p_TagID);
    END IF;

    -- 3) Check if product is already linked to this tag (composite PK -> avoid duplicate error)
    SELECT COUNT(*) INTO v_AlreadyLinked
    FROM ProductTags
    WHERE ProductID = p_ProductID
      AND TagID = p_TagID;

    IF v_AlreadyLinked > 0 THEN
        SET p_Success = 1;
        SET p_Message = 'Ce tag est déjà associé à ce produit.';
    ELSE
        START TRANSACTION;

        -- 4) Insert into ProductTags
        INSERT INTO ProductTags (ProductID, TagID)
        VALUES (p_ProductID, p_TagID);

        -- 5) Update search index
        UPDATE ProductSearchIndex
        SET SearchText = CONCAT(SearchText, ' ', p_TagName)
        WHERE ProductID = p_ProductID;

        SET p_Success = 1;
        SET p_Message = 'Tag associé avec succès.';

        COMMIT;
    END IF;
END $$

DELIMITER ;