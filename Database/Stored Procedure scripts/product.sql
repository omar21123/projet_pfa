-- ============================================================
-- SP_CreateProduct
-- ============================================================
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
        SET p_Success = 0;
        SET p_ProductID = NULL;
        SET p_Message = 'Une erreur est survenue lors de la création du produit.';
    END;

    IF p_Barcode IS NOT NULL AND EXISTS (
        SELECT 1 FROM Products WHERE Barcode = p_Barcode AND DeletedAt IS NULL
    ) THEN
        SET p_Success = 0;
        SET p_ProductID = NULL;
        SET p_Message = 'Ce code-barres est déjà utilisé par un autre produit.';
    ELSE
        INSERT INTO Products (
            VendorID, BrandID, ModelID, Name, Barcode, Description, BasePrice, Stock,
            Status, CreatedAt, UpdatedAt, DeletedAt, IsActive,
            RefuseNotes, RefusedBy, RefuseAt, RefuseAttempt,
            ValidatorID, ValidationNotes, ValidationDate,
            IsBlocked, BlokedBy, BlockedDate, BlockedNotes
        )
        VALUES (
            p_VendorID, p_BrandID, p_ModelID, p_Name, p_Barcode, p_Description,
            IFNULL(p_BasePrice, 0.00), IFNULL(p_Stock, 0),
            1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL, 1,
            NULL, NULL, NULL, 1,
            NULL, NULL, NULL,
            0, NULL, NULL, NULL
        );

        SET p_ProductID = LAST_INSERT_ID();

        IF p_BrandID IS NOT NULL THEN
            SELECT Name INTO v_BrandName FROM Brands WHERE BrandID = p_BrandID;
        END IF;

        IF p_ModelID IS NOT NULL THEN
            SELECT Name INTO v_ModelName FROM Models WHERE ModelID = p_ModelID;
        END IF;

        SET v_SearchText = CONCAT_WS(' ', v_BrandName, v_ModelName, p_Name);

        INSERT INTO ProductSearchIndex (ProductID, SearchText)
        VALUES (p_ProductID, v_SearchText);

        -- Entry 1: Name alone
        SET v_NormalizedName = LOWER(TRIM(p_Name));
        SELECT COUNT(*) INTO v_ExistingCount FROM SearchDictionary WHERE NormalizedText = v_NormalizedName;

        IF v_ExistingCount > 0 THEN
            UPDATE SearchDictionary
            SET DisplayText = p_Name, SourceType = 6, SourceID = p_ProductID, IsActive = 1, UpdatedAt = NOW()
            WHERE NormalizedText = v_NormalizedName;
        ELSE
            INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
            VALUES (p_Name, v_NormalizedName, 6, p_ProductID);
        END IF;

        -- Entry 2: BrandName + Name
        IF p_BrandID IS NOT NULL AND v_BrandName IS NOT NULL THEN
            SET v_DisplayBrandName = CONCAT(v_BrandName, ' ', p_Name);
            SET v_NormalizedBrandName = LOWER(TRIM(v_DisplayBrandName));
            SET v_ExistingCount = 0;
            SELECT COUNT(*) INTO v_ExistingCount FROM SearchDictionary WHERE NormalizedText = v_NormalizedBrandName;

            IF v_ExistingCount > 0 THEN
                UPDATE SearchDictionary
                SET DisplayText = v_DisplayBrandName, SourceType = 6, SourceID = p_ProductID, IsActive = 1, UpdatedAt = NOW()
                WHERE NormalizedText = v_NormalizedBrandName;
            ELSE
                INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
                VALUES (v_DisplayBrandName, v_NormalizedBrandName, 6, p_ProductID);
            END IF;
        END IF;

        -- Entry 3: BrandName + ModelName + Name
        IF p_BrandID IS NOT NULL AND v_BrandName IS NOT NULL
           AND p_ModelID IS NOT NULL AND v_ModelName IS NOT NULL THEN
            SET v_DisplayBrandModelName = CONCAT(v_BrandName, ' ', v_ModelName, ' ', p_Name);
            SET v_NormalizedBrandModelName = LOWER(TRIM(v_DisplayBrandModelName));
            SET v_ExistingCount = 0;
            SELECT COUNT(*) INTO v_ExistingCount FROM SearchDictionary WHERE NormalizedText = v_NormalizedBrandModelName;

            IF v_ExistingCount > 0 THEN
                UPDATE SearchDictionary
                SET DisplayText = v_DisplayBrandModelName, SourceType = 6, SourceID = p_ProductID, IsActive = 1, UpdatedAt = NOW()
                WHERE NormalizedText = v_NormalizedBrandModelName;
            ELSE
                INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
                VALUES (v_DisplayBrandModelName, v_NormalizedBrandModelName, 6, p_ProductID);
            END IF;
        END IF;

        -- Entry 4: ModelName + Name
        IF p_ModelID IS NOT NULL AND v_ModelName IS NOT NULL THEN
            SET v_DisplayModelName = CONCAT(v_ModelName, ' ', p_Name);
            SET v_NormalizedModelName = LOWER(TRIM(v_DisplayModelName));
            SET v_ExistingCount = 0;
            SELECT COUNT(*) INTO v_ExistingCount FROM SearchDictionary WHERE NormalizedText = v_NormalizedModelName;

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
    END IF;
END $$

DELIMITER ;


-- ============================================================
-- SP_CreateProductResource
-- ============================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS SP_CreateProductResource $$

CREATE PROCEDURE SP_CreateProductResource (
    IN  p_ProductID      INT,
    IN  p_ResourceType   VARCHAR(100),
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
        SET p_Success = 0;
        SET p_ResourceID = NULL;
        IF p_Message IS NULL OR p_Message = '' THEN
            SET p_Message = 'Une erreur est survenue lors de l''ajout de la ressource.';
        END IF;
    END;

    SELECT ID INTO v_ResourcesTypeID
    FROM ResourcesTypes
    WHERE LOWER(Name) = LOWER(p_ResourceType)
    LIMIT 1;

    IF v_ResourcesTypeID IS NULL THEN
        SET p_Message = 'Type de ressource invalide.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid ResourceType: type not found in ResourcesTypes';
    END IF;

    SELECT COUNT(*) INTO v_RoleExists
    FROM ResourcesRoles
    WHERE RoleID = p_ResourceRole;

    IF v_RoleExists = 0 THEN
        SET p_Message = 'Rôle de ressource invalide.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid ResourceRole: role not found in ResourcesRoles';
    END IF;

    INSERT INTO ProductResources (
        ProductID, ResourcesPath, ResourcesTypeID, ResourceRoleID
    )
    VALUES (
        p_ProductID, p_ResourcePath, v_ResourcesTypeID, p_ResourceRole
    );

    SET p_ResourceID = LAST_INSERT_ID();
    SET p_Success = 1;
    SET p_Message = 'Ressource ajoutée avec succès.';
END $$

DELIMITER ;


-- ============================================================
-- SP_CreateProductCategory
-- ============================================================
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
        SET p_Success = 0;
        IF p_Message IS NULL OR p_Message = '' THEN
            SET p_Message = 'Une erreur est survenue lors de l''association de la catégorie.';
        END IF;
    END;

    SELECT COUNT(*) INTO v_CategoryExists
    FROM Categories
    WHERE CategoryID = p_CategoryID;

    IF v_CategoryExists = 0 THEN
        SET p_Message = 'Catégorie introuvable.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid CategoryID: category not found';
    END IF;

    SELECT ParentCategoryID INTO v_ParentCategoryID
    FROM Categories
    WHERE CategoryID = p_CategoryID;

    IF v_ParentCategoryID IS NULL THEN
        SET v_IsPrimary = 1;
    ELSE
        SET v_IsPrimary = 0;
    END IF;

    INSERT INTO ProductCategories (ProductID, CategoryID, IsPrimary)
    VALUES (p_ProductID, p_CategoryID, v_IsPrimary);

    SELECT Slug INTO v_Slug
    FROM Categories
    WHERE CategoryID = p_CategoryID;

    UPDATE ProductSearchIndex
    SET SearchText = CONCAT(SearchText, ' ', v_Slug)
    WHERE ProductID = p_ProductID;

    SET p_Success = 1;
    SET p_Message = 'Catégorie associée avec succès.';
END $$

DELIMITER ;


-- ============================================================
-- SP_CreateProductsConfigAttributeByName  (inner SP)
-- ============================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS SP_CreateProductsConfigAttributeByName $$

CREATE PROCEDURE SP_CreateProductsConfigAttributeByName(
    IN p_Name VARCHAR(150),
    OUT p_AttributeID INT
)
BEGIN
    DECLARE v_NormalizedText VARCHAR(255);
    DECLARE v_ExistingSearchCount INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RESIGNAL;
    END;

    SET v_NormalizedText = LOWER(TRIM(p_Name));

    INSERT INTO ProductsConfigAttribute (Name, DisplayOrder)
    VALUES (p_Name, 0);

    SET p_AttributeID = LAST_INSERT_ID();

    SELECT COUNT(*) INTO v_ExistingSearchCount
    FROM SearchDictionary
    WHERE NormalizedText = v_NormalizedText;

    IF v_ExistingSearchCount > 0 THEN
        UPDATE SearchDictionary
        SET DisplayText = p_Name, SourceType = 4, SourceID = p_AttributeID, IsActive = 1, UpdatedAt = NOW()
        WHERE NormalizedText = v_NormalizedText;
    ELSE
        INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
        VALUES (p_Name, v_NormalizedText, 4, p_AttributeID);
    END IF;
END$$

DELIMITER ;


-- ============================================================
-- SP_GetOrCreateProductsConfigAttributeByName
-- ============================================================
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
        SET p_Success = 0;
        SET p_AttributeID = NULL;
        SET p_Message = 'Une erreur est survenue lors de la récupération de l''attribut.';
    END;

    SELECT AttributeID INTO p_AttributeID
    FROM ProductsConfigAttribute
    WHERE Name = p_ConfigName
    LIMIT 1;

    IF p_AttributeID IS NOT NULL THEN
        SET p_Success = 1;
        SET p_Message = 'Attribut existant récupéré avec succès.';
    ELSE
        CALL SP_CreateProductsConfigAttributeByName(p_ConfigName, p_AttributeID);
        SET p_Success = 1;
        SET p_Message = 'Attribut créé avec succès.';
    END IF;

    SELECT p_AttributeID AS AttributeID, p_Success AS Success, p_Message AS Message;
END $$

DELIMITER ;


-- ============================================================
-- SP_CreateConfigAttributeOptionByName  (inner SP)
-- ============================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS SP_CreateConfigAttributeOptionByName $$

CREATE PROCEDURE SP_CreateConfigAttributeOptionByName(
    IN p_ProductsConfigAttributeID INT,
    IN p_OptionLabel VARCHAR(150),
    OUT p_OptionID INT
)
BEGIN
    DECLARE v_AttributeName VARCHAR(150) DEFAULT NULL;
    DECLARE v_NormalizedLabel VARCHAR(255);
    DECLARE v_DisplayWithAttribute VARCHAR(255);
    DECLARE v_NormalizedWithAttribute VARCHAR(255);
    DECLARE v_ExistingSearchCount INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RESIGNAL;
    END;

    SELECT Name INTO v_AttributeName
    FROM ProductsConfigAttribute
    WHERE AttributeID = p_ProductsConfigAttributeID;

    IF v_AttributeName IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'L''attribut spécifié n''existe pas.';
    END IF;

    SET v_NormalizedLabel = LOWER(TRIM(p_OptionLabel));

    INSERT INTO ConfigAttributeOptions (ProductsConfigAttributeID, OptionLabel, OptionValue, DisplayOrder, IsDefaultForAttribute)
    VALUES (p_ProductsConfigAttributeID, p_OptionLabel, p_OptionLabel, 0, 0);

    SET p_OptionID = LAST_INSERT_ID();

    SELECT COUNT(*) INTO v_ExistingSearchCount
    FROM SearchDictionary
    WHERE NormalizedText = v_NormalizedLabel;

    IF v_ExistingSearchCount > 0 THEN
        UPDATE SearchDictionary
        SET DisplayText = p_OptionLabel, SourceType = 5, SourceID = p_OptionID, IsActive = 1, UpdatedAt = NOW()
        WHERE NormalizedText = v_NormalizedLabel;
    ELSE
        INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
        VALUES (p_OptionLabel, v_NormalizedLabel, 5, p_OptionID);
    END IF;

    SET v_DisplayWithAttribute = CONCAT(v_AttributeName, ' ', p_OptionLabel);
    SET v_NormalizedWithAttribute = LOWER(TRIM(v_DisplayWithAttribute));

    SET v_ExistingSearchCount = 0;
    SELECT COUNT(*) INTO v_ExistingSearchCount
    FROM SearchDictionary
    WHERE NormalizedText = v_NormalizedWithAttribute;

    IF v_ExistingSearchCount > 0 THEN
        UPDATE SearchDictionary
        SET DisplayText = v_DisplayWithAttribute, SourceType = 5, SourceID = p_OptionID, IsActive = 1, UpdatedAt = NOW()
        WHERE NormalizedText = v_NormalizedWithAttribute;
    ELSE
        INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
        VALUES (v_DisplayWithAttribute, v_NormalizedWithAttribute, 5, p_OptionID);
    END IF;
END$$

DELIMITER ;


-- ============================================================
-- SP_CreateProductDetailByOptionName
-- ============================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS SP_CreateProductDetailByOptionName $$

CREATE PROCEDURE SP_CreateProductDetailByOptionName (
    IN  p_ProductID  INT,
    IN  p_ConfigID   INT,
    IN  p_Name       VARCHAR(150),
    IN  p_IsDefault  TINYINT,
    OUT p_DetailID   INT,
    OUT p_OptionID   INT,
    OUT p_Success    TINYINT,
    OUT p_Message    VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_Success = 0;
        SET p_DetailID = NULL;
        IF p_Message IS NULL OR p_Message = '' THEN
            SET p_Message = 'Une erreur est survenue lors de l''ajout du détail produit.';
        END IF;
    END;

    SELECT OptionID INTO p_OptionID
    FROM ConfigAttributeOptions
    WHERE LOWER(OptionValue) = LOWER(p_Name)
      AND ProductsConfigAttributeID = p_ConfigID
    LIMIT 1;

    IF p_OptionID IS NULL THEN
        CALL SP_CreateConfigAttributeOptionByName(p_ConfigID, p_Name, p_OptionID);
    END IF;

    IF p_IsDefault = 1 THEN
        UPDATE ConfigAttributeOptions
        SET IsDefaultForAttribute = 0
        WHERE ProductsConfigAttributeID = p_ConfigID;

        UPDATE ConfigAttributeOptions
        SET IsDefaultForAttribute = 1
        WHERE OptionID = p_OptionID;
    END IF;

    INSERT INTO ProductDetails (ProductID, ProductsConfigAttributeID, OptionID)
    VALUES (p_ProductID, p_ConfigID, p_OptionID);

    SET p_DetailID = LAST_INSERT_ID();
    SET p_Success = 1;
    SET p_Message = 'Détail produit ajouté avec succès.';
END $$

DELIMITER ;


-- ============================================================
-- SP_CreateTagByName  (inner SP)
-- ============================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS SP_CreateTagByName $$

CREATE PROCEDURE SP_CreateTagByName(
    IN p_Name VARCHAR(100),
    OUT p_TagID INT
)
BEGIN
    DECLARE v_NormalizedText VARCHAR(255);
    DECLARE v_ExistingTagCount INT DEFAULT 0;
    DECLARE v_ExistingSearchCount INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RESIGNAL;
    END;

    SET v_NormalizedText = LOWER(TRIM(p_Name));

    SELECT COUNT(*) INTO v_ExistingTagCount
    FROM Tags
    WHERE Name = p_Name;

    IF v_ExistingTagCount > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Un tag avec ce nom existe déjà.';
    END IF;

    INSERT INTO Tags (Name) VALUES (p_Name);

    SET p_TagID = LAST_INSERT_ID();

    SELECT COUNT(*) INTO v_ExistingSearchCount
    FROM SearchDictionary
    WHERE NormalizedText = v_NormalizedText;

    IF v_ExistingSearchCount > 0 THEN
        UPDATE SearchDictionary
        SET DisplayText = p_Name, SourceType = 2, SourceID = p_TagID, IsActive = 1, UpdatedAt = NOW()
        WHERE NormalizedText = v_NormalizedText;
    ELSE
        INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
        VALUES (p_Name, v_NormalizedText, 2, p_TagID);
    END IF;
END$$

DELIMITER ;


-- ============================================================
-- SP_AddProductTagByName
-- ============================================================
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
        SET p_Success = 0;
        SET p_TagID = NULL;
        IF p_Message IS NULL OR p_Message = '' THEN
            SET p_Message = 'Une erreur est survenue lors de l''ajout du tag.';
        END IF;
    END;

    SELECT TagID INTO p_TagID
    FROM Tags
    WHERE Name = p_TagName
    LIMIT 1;

    IF p_TagID IS NULL THEN
        CALL SP_CreateTagByName(p_TagName, p_TagID);
    END IF;

    SELECT COUNT(*) INTO v_AlreadyLinked
    FROM ProductTags
    WHERE ProductID = p_ProductID
      AND TagID = p_TagID;

    IF v_AlreadyLinked > 0 THEN
        SET p_Success = 1;
        SET p_Message = 'Ce tag est déjà associé à ce produit.';
    ELSE
        INSERT INTO ProductTags (ProductID, TagID)
        VALUES (p_ProductID, p_TagID);

        UPDATE ProductSearchIndex
        SET SearchText = CONCAT(SearchText, ' ', p_TagName)
        WHERE ProductID = p_ProductID;

        SET p_Success = 1;
        SET p_Message = 'Tag associé avec succès.';
    END IF;
END $$

DELIMITER ;

DROP PROCEDURE IF EXISTS SP_GetPublicProductInfo;

DELIMITER $$

CREATE PROCEDURE SP_GetPublicProductInfo(
    IN  p_ProductID INT,
    OUT p_success   TINYINT,
    OUT p_message   VARCHAR(255)
)
BEGIN
    DECLARE v_Exists INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_success = 0;
        SET p_message = 'Erreur lors de la récupération des informations du produit.';
    END;

    -- Existence + visibilité (produit actif, non bloqué)
    SELECT COUNT(*) INTO v_Exists
    FROM Products
    WHERE ProductID = p_ProductID
      AND IsActive = 1
      AND IsBlocked = 0;

    IF v_Exists = 0 THEN
        SET p_success = 0;
        SET p_message = 'Produit introuvable ou non disponible.';
    ELSE
        SELECT
            p.ProductID,
            p.Name AS ProductName,
            p.Description AS ProductDesc,
            p.BasePrice,
            IFNULL(b.Name, 'No Band') AS BrandName,
            IFNULL(b.BrandID, 0) AS BrandID,
            IFNULL(m.Name, 'No Model') AS ModelName,
            p.Stock,
            (SELECT COUNT(*) FROM OrderItems o WHERE o.ProductID = p.ProductID) AS TotalOrders,
            (SELECT COUNT(*) FROM WishListItems wli WHERE wli.ProductID = p.ProductID) AS TotalWishlists,
            (SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID) AS TotalLikes
        FROM Products p
        LEFT JOIN Brands b ON b.BrandID = p.BrandID
        LEFT JOIN Models m ON m.ModelID = p.ModelID
        WHERE p.ProductID = p_ProductID;

        SET p_success = 1;
        SET p_message = 'OK';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_GetProductCategories(
    IN p_ProductID INT
)
BEGIN
    SELECT c.Name, pc.IsPrimary
    FROM ProductCategories pc
    JOIN Categories c ON pc.CategoryID = c.CategoryID
    WHERE pc.ProductID = p_ProductID;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS SP_GetProductConfigs;

DELIMITER $$

CREATE PROCEDURE SP_GetProductConfigs(
    IN p_ProductID INT
)
BEGIN
    -- DISTINCT car ProductDetails a une ligne par option, donc un même
    -- ProductsConfigAttributeID peut apparaître plusieurs fois (ex: Couleur
    -- avec 3 options = 3 lignes). On ne veut ici que la liste des attributs
    -- (configId/configName), pas encore leurs options.
    SELECT DISTINCT pd.ProductsConfigAttributeID, pc.Name
    FROM ProductDetails pd
    JOIN ProductsConfigAttribute pc ON pc.AttributeID = pd.ProductsConfigAttributeID
    WHERE pd.ProductID = p_ProductID;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS SP_GetProductConfigOptions;

DELIMITER $$

CREATE PROCEDURE SP_GetProductConfigOptions(
    IN p_ProductID INT,
    IN p_ConfigID  INT
)
BEGIN
    SELECT o.OptionID, o.OptionLabel, o.OptionValue, o.IsDefaultForAttribute as IsDefault
    FROM ProductDetails d
    JOIN ConfigAttributeOptions o ON o.OptionID = d.OptionID
    WHERE d.ProductID = p_ProductID
      AND d.ProductsConfigAttributeID = p_ConfigID;
END$$

DELIMITER ;



DROP PROCEDURE IF EXISTS SP_GetProductImages;

DELIMITER $$

CREATE PROCEDURE SP_GetProductImages(
    IN p_ProductID INT
)
BEGIN
    SELECT ResourcesPath
    FROM ProductResources
    WHERE ProductID = p_ProductID
      AND ResourceRoleID = 2
      AND ResourcesTypeID IN (3, 5);
END$$

DELIMITER ;



DROP PROCEDURE IF EXISTS SP_GetProductCombinations;

DELIMITER $$

CREATE PROCEDURE SP_GetProductCombinations(
    IN p_ProductID INT
)
BEGIN
    SELECT c.CombinationID, c.SKU, c.Price, c.CompareAtPrice, c.Stock, c.ImagePath, c.IsDefault
    FROM ProductOptionsCombiniason c
    WHERE c.IsActive = 1
      AND c.ProductID = p_ProductID;
END$$

DELIMITER ;


DROP PROCEDURE IF EXISTS SP_GetCombinationConfigs;

DELIMITER $$

CREATE PROCEDURE SP_GetCombinationConfigs(
    IN p_CombinationID INT
)
BEGIN
    SELECT d.ProductsConfigAttributeID, d.OptionID
    FROM ProductOptionsCombiniasonDetails d
    WHERE d.CombinationID = p_CombinationID;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS SP_GetProductTags;

DELIMITER $$

CREATE PROCEDURE SP_GetProductTags(
    IN p_ProductID INT
)
BEGIN
    SELECT p.TagID, t.Name, t.Color
    FROM ProductTags p
    JOIN Tags t ON p.TagID = t.TagID
    WHERE t.IsActive = 1
      AND p.ProductID = p_ProductID;
END$$

DELIMITER ;


DROP PROCEDURE IF EXISTS SP_GetProductPromotion;

DELIMITER $$

CREATE PROCEDURE SP_GetProductPromotion(
    IN p_ProductID INT
)
BEGIN
    SELECT
        p.PromotionID,
        p.Name,
        p.Description,
        ty.Code AS DiscountCode,
        ty.Label AS DiscountLabel,
        p.DiscountValue,
        p.MaxDiscountAmount,
        p.MinOrderAmount,
        p.UsageLimitTotal,
        p.UsageCount,
        p.UsageLimitPerUser,
        p.StartDate,
        p.EndDate
    FROM Promotions p
    JOIN PromotionDiscountTypes ty ON ty.DiscountTypeID = p.DiscountTypeID
    WHERE p.ScopeTypeID = 1
      AND p.StatusID = 2
      AND p.IsActive = 1
      AND p.TargetProductID = p_ProductID;
END$$

DELIMITER ;



DROP PROCEDURE IF EXISTS SP_HasActivePromotion;

DELIMITER $$

CREATE PROCEDURE SP_HasActivePromotion(
    IN  p_ProductID INT,
    OUT p_Found     TINYINT
)
BEGIN
    SELECT COUNT(*) > 0 INTO p_Found
    FROM Promotions p
    JOIN PromotionDiscountTypes ty ON ty.DiscountTypeID = p.DiscountTypeID
    WHERE p.ScopeTypeID = 1
      AND p.StatusID = 2
      AND p.IsActive = 1
      AND NOW() BETWEEN p.StartDate AND p.EndDate
            AND p.UsageCount < p.UsageLimitTotal

      AND p.TargetProductID = p_ProductID;
END$$

DELIMITER ;
DROP PROCEDURE IF EXISTS SP_GetSimilarProductsByCategory;
DELIMITER $$

CREATE PROCEDURE SP_GetSimilarProductsByCategory (
    IN v_ProductID      INT,
    IN v_UserPublicID    VARCHAR(64),
    IN v_Limit          INT,
    OUT v_Success        BOOLEAN,
    OUT v_Message        VARCHAR(255)
)
BEGIN
    DECLARE v_CategoryCount INT DEFAULT 0;
    DECLARE v_UserID         INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetSimilarProductsByCategory',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('ProductID', v_ProductID, 'Limit', v_Limit)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits similaires.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_Limit IS NULL OR v_Limit < 1 THEN
        SET v_Limit = 10;
    ELSEIF v_Limit > 50 THEN
        SET v_Limit = 50;
    END IF;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID
        FROM Users
        WHERE PublicID = v_UserPublicID
        LIMIT 1;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = v_ProductID) THEN
        SET v_Message = 'Produit introuvable.';
    ELSE
        SELECT COUNT(*) INTO v_CategoryCount
        FROM ProductCategories
        WHERE ProductID = v_ProductID;

        IF v_CategoryCount = 0 THEN
            SET v_Success = TRUE;
            SET v_Message = 'Ce produit n''a aucune catégorie renseignée.';
            SELECT NULL AS ProductID LIMIT 0;
        ELSE
            SET v_Success = TRUE;
            SET v_Message = 'OK';

            SELECT
                p.ProductID                       AS ProductID,
                p.Name                            AS ProductName,
                pr.ResourcesPath                  AS ProductDefaultImage,
                p.Description                     AS Description,
                p.BasePrice                       AS DefaultPrice,
                IFNULL(b.Name, 'No Brand')        AS BrandName,
                IFNULL(b.LogoURL ,NULL)               AS BrandLogo,
                IFNULL(m.Name, 'No Model')        AS ModelName,

                (SELECT COUNT(*) FROM WishListItems wli WHERE wli.ProductID = p.ProductID) AS TotalWishlist,
                (SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID) AS TotalLikes,
                (SELECT COUNT(*) FROM OrderItems o WHERE o.ProductID = p.ProductID) AS TotalOrders,

                CASE
                WHEN v_UserID IS NOT NULL AND EXISTS (
                    SELECT 1 FROM ProductLikes pl2
                    WHERE pl2.ProductID = p.ProductID AND pl2.UserID = v_UserID
                ) THEN 1 ELSE 0
            END AS IsLiked,
            CASE
                WHEN v_UserID IS NOT NULL AND EXISTS (
                    SELECT 1 FROM WishListItems w2
                    INNER JOIN WishLists wq ON wq.WishListID = w2.WishListID
                    WHERE w2.ProductID = p.ProductID AND wq.UserID = v_UserID
                ) THEN 1 ELSE 0
            END AS IsWishedList
            FROM Products p
            INNER JOIN ProductCategories pc ON pc.ProductID = p.ProductID
            LEFT JOIN Brands b ON b.BrandID = p.BrandID
            LEFT JOIN Models m ON m.ModelID = p.ModelID
            LEFT JOIN ProductResources pr
                ON pr.ProductID = p.ProductID
                AND pr.ResourceRoleID = 2
            WHERE pc.CategoryID IN (
                    SELECT CategoryID FROM ProductCategories WHERE ProductID = v_ProductID
                  )
              AND p.ProductID != v_ProductID
            GROUP BY
                p.ProductID, p.Name, p.Description, p.BasePrice,
                b.Name, b.Logo, m.Name, pr.ResourcesPath, v_UserID
            ORDER BY
                -- Plus un produit partage de catégories avec le produit de référence,
                -- plus il est considéré similaire (ex: 2 catégories communes > 1 seule).
                SharedCategoriesCount DESC,
                (SELECT COUNT(*) FROM OrderItems o WHERE o.ProductID = p.ProductID) DESC,
                (SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID) DESC
            LIMIT v_Limit;
        END IF;
    END IF;
END$$

DELIMITER ;
DELIMITER $$
CREATE PROCEDURE SP_GetProductsForVendor (
    IN v_UserPublicID VARCHAR(36),
    IN v_Status       INT,
    IN v_Search       VARCHAR(255),
    IN v_IsActive     TINYINT,
    IN v_IsBlocked    TINYINT,
    IN v_PageNumber   INT,
    IN v_PageSize     INT,
    OUT v_TotalCount  INT,
    OUT v_Success     BOOLEAN,
    OUT v_Message     VARCHAR(255)
)
BEGIN
    DECLARE v_UserID   INT DEFAULT NULL;
    DECLARE v_VendorID INT DEFAULT NULL;
    DECLARE v_Offset   INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetProductsForVendor',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('UserPublicID', v_UserPublicID, 'Status', v_Status, 'Search', v_Search)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits.';
        SET v_TotalCount = 0;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_TotalCount = 0;

    IF v_PageNumber IS NULL OR v_PageNumber < 1 THEN
        SET v_PageNumber = 1;
    END IF;

    IF v_PageSize IS NULL OR v_PageSize < 1 THEN
        SET v_PageSize = 20;
    ELSEIF v_PageSize > 100 THEN
        SET v_PageSize = 100;
    END IF;

    SET v_Offset = (v_PageNumber - 1) * v_PageSize;

    -- Résolution PublicID -> UserID -> VendorProfileID.
    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        SELECT VendorProfileID INTO v_VendorID FROM VendorProfiles WHERE UserID = v_UserID;

        IF v_VendorID IS NULL THEN
            SET v_Message = 'Profil vendeur introuvable pour cet utilisateur';
        ELSE
            SET v_Success = TRUE;
            SET v_Message = 'OK';

            SELECT COUNT(*) INTO v_TotalCount
            FROM Products p
            WHERE p.VendorID = v_VendorID
              AND (v_Status IS NULL OR p.Status = v_Status)
              AND (v_IsActive IS NULL OR p.IsActive = v_IsActive)
              AND (v_IsBlocked IS NULL OR p.IsBlocked = v_IsBlocked)
              AND (
                    v_Search IS NULL OR v_Search = ''
                    OR p.Name LIKE CONCAT('%', v_Search, '%')
                    OR p.Barcode LIKE CONCAT('%', v_Search, '%')
                  );

            SELECT
                p.ProductID,
                p.Name,
                p.Barcode,
                p.BasePrice,
                p.Stock,
                ps.Id AS status,
                ps.Libelle AS statusLabel,
                p.IsActive,
                p.IsBlocked,
                b.BrandID,
                b.Name AS BrandName,
                m.ModelID,
                m.Name AS ModelName,
                (
                    SELECT pr.ResourcesPath
                    FROM ProductResources pr
                    WHERE pr.ProductID = p.ProductID
                      AND pr.ResourceRoleID = 2
                      AND pr.ResourcesTypeID IN (3, 5)
                    LIMIT 1
                ) AS MainImage,
                p.CreatedAt,
                p.UpdatedAt
            FROM Products p
            INNER JOIN ProductStatus ps ON ps.Id = p.Status
            LEFT JOIN Brands b ON b.BrandID = p.BrandID
            LEFT JOIN Models m ON m.ModelID = p.ModelID
            WHERE p.VendorID = v_UserID
              AND (v_Status IS NULL OR p.Status = v_Status)
              AND (v_IsActive IS NULL OR p.IsActive = v_IsActive)
              AND (v_IsBlocked IS NULL OR p.IsBlocked = v_IsBlocked)
              AND (
                    v_Search IS NULL OR v_Search = ''
                    OR p.Name LIKE CONCAT('%', v_Search, '%')
                    OR p.Barcode LIKE CONCAT('%', v_Search, '%')
                  )
            ORDER BY p.CreatedAt DESC
            LIMIT v_PageSize OFFSET v_Offset;
        END IF;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `SP_GetProductAllowedPayments`(
    IN p_ProductID INT
)
BEGIN
    SELECT pm.PaymentMethodID, pm.Name, pm.Code, pm.IconURL, pm.WithdrawTax, pm.IsOnline
    FROM ProductAllowedPayements pap
    JOIN PaymentMethods pm ON pm.PaymentMethodID = pap.PayementMethodID
    WHERE pap.ProductID = p_ProductID;
END

DELIMITER ;



--modified

-- =====================================================================
-- DROP STATEMENTS
-- =====================================================================
DROP PROCEDURE IF EXISTS SP_GetSimilarProductsByBrandOrModel;
DROP PROCEDURE IF EXISTS SP_GetSimilarProductsByName;

-- =====================================================================
-- SP_GetSimilarProductsByBrandOrModel
-- =====================================================================
DELIMITER $$

CREATE PROCEDURE SP_GetSimilarProductsByBrandOrModel (
    IN v_ProductID      INT,
    IN v_UserPublicID    VARCHAR(64),
    IN v_Limit          INT,
    OUT v_Success        BOOLEAN,
    OUT v_Message        VARCHAR(255)
)
BEGIN
    DECLARE v_BrandID INT;
    DECLARE v_ModelID INT;
    DECLARE v_UserID   INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetSimilarProductsByBrandOrModel',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('ProductID', v_ProductID, 'Limit', v_Limit)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits similaires.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_Limit IS NULL OR v_Limit < 1 THEN
        SET v_Limit = 10;
    ELSEIF v_Limit > 50 THEN
        SET v_Limit = 50;
    END IF;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID
        FROM Users
        WHERE PublicID = v_UserPublicID
        LIMIT 1;
    END IF;

    -- Récupère BrandID/ModelID du produit de référence.
    SELECT BrandID, ModelID INTO v_BrandID, v_ModelID
    FROM Products
    WHERE ProductID = v_ProductID;

    -- Une ligne existe même si BrandID/ModelID sont NULL -> distinguer
    -- "produit introuvable" de "produit trouvé mais sans marque/modèle".
    IF ROW_COUNT() = 0 THEN
        SET v_Message = 'Produit introuvable.';
    ELSEIF v_BrandID IS NULL AND v_ModelID IS NULL THEN
        -- Rien à comparer : le produit n'a ni marque ni modèle renseigné.
        SET v_Success = TRUE;
        SET v_Message = 'Ce produit n''a ni marque ni modèle renseigné.';
        SELECT NULL AS ProductID LIMIT 0;
    ELSE
        SET v_Success = TRUE;
        SET v_Message = 'OK';

        WITH ActivePromotions AS (
            SELECT
                p.TargetProductID,
                pt.Code           AS PromotionCode,
                p.DiscountValue   AS PromotionDiscountValue,
                ROW_NUMBER() OVER (
                    PARTITION BY p.TargetProductID
                    ORDER BY p.EndDate ASC
                ) AS rn
            FROM Promotions p
            INNER JOIN PromotionDiscountTypes pt ON pt.DiscountTypeID = p.DiscountTypeID
            WHERE p.ScopeTypeID = 1
              AND p.StatusID = 2
              AND p.IsActive = 1
              AND NOW() BETWEEN p.StartDate AND p.EndDate
              AND p.UsageCount < p.UsageLimitTotal
        )

        SELECT
            p.ProductID                       AS ProductID,
            p.Name                            AS ProductName,
            pr.ResourcesPath                  AS ProductDefaultImage,
            p.Description                     AS Description,
            p.BasePrice                       AS DefaultPrice,
            IFNULL(b.Name, 'No Brand')        AS BrandName,
            IFNULL(b.LogoURL, NULL)               AS BrandLogo,
            IFNULL(m.Name, 'No Model')        AS ModelName,

            (SELECT COUNT(*) FROM WishListItems wli WHERE wli.ProductID = p.ProductID) AS TotalWishlist,
            (SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID) AS TotalLikes,
            (SELECT COUNT(*) FROM OrderItems o WHERE o.ProductID = p.ProductID) AS TotalOrders,

           CASE
                WHEN v_UserID IS NOT NULL AND EXISTS (
                    SELECT 1 FROM ProductLikes pl2
                    WHERE pl2.ProductID = p.ProductID AND pl2.UserID = v_UserID
                ) THEN 1 ELSE 0
            END AS IsLiked,
            CASE
                WHEN v_UserID IS NOT NULL AND EXISTS (
                    SELECT 1 FROM WishListItems w2
                    INNER JOIN WishLists wq ON wq.WishListID = w2.WishListID
                    WHERE w2.ProductID = p.ProductID AND wq.UserID = v_UserID
                ) THEN 1 ELSE 0
            END AS IsWishedList,

            IF(ap.TargetProductID IS NOT NULL, 1, 0) AS HasPromo,
            ap.PromotionCode                          AS PromotionCode,
            ap.PromotionDiscountValue                 AS PromotionDiscountValue

        FROM Products p
        LEFT JOIN Brands b ON b.BrandID = p.BrandID
        LEFT JOIN Models m ON m.ModelID = p.ModelID
        LEFT JOIN ProductResources pr
            ON pr.ProductID = p.ProductID
            AND pr.ResourceRoleID = 2
        LEFT JOIN ActivePromotions ap
            ON ap.TargetProductID = p.ProductID
            AND ap.rn = 1
        WHERE p.ProductID != v_ProductID
          AND (
                (v_BrandID IS NOT NULL AND p.BrandID = v_BrandID)
             OR (v_ModelID IS NOT NULL AND p.ModelID = v_ModelID)
          )
        ORDER BY
            -- Même modèle prioritaire sur simple même marque (signal plus fort de similarité).
            (CASE WHEN v_ModelID IS NOT NULL AND p.ModelID = v_ModelID THEN 1 ELSE 0 END) DESC,
            (SELECT COUNT(*) FROM OrderItems o WHERE o.ProductID = p.ProductID) DESC,
            (SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID) DESC
        LIMIT v_Limit;
    END IF;
END$$

DELIMITER ;

-- =====================================================================
-- SP_GetSimilarProductsByName
-- =====================================================================
DELIMITER $$

CREATE PROCEDURE SP_GetSimilarProductsByName(
    IN v_ProductID      INT,
    IN v_UserPublicID    VARCHAR(64),
    IN v_Limit          INT,
    OUT v_Success        BOOLEAN,
    OUT v_Message        VARCHAR(255)
)
BEGIN
    DECLARE v_Name       VARCHAR(255);
    DECLARE v_FirstWord   VARCHAR(255);
    DECLARE v_UserID       INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno = MYSQL_ERRNO,
            @p_message = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (
            ProcedureName,
            ErrorSQLState,
            ErrorNumber,
            ErrorMessage,
            ContextData
        )
        VALUES (
            'SP_GetSimilarProductsByName',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'ProductID', v_ProductID,
                'Limit', v_Limit
            )
        );

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits similaires.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_Limit IS NULL OR v_Limit < 1 THEN
        SET v_Limit = 10;
    ELSEIF v_Limit > 50 THEN
        SET v_Limit = 50;
    END IF;

    -- Résolution optionnelle de l'utilisateur (pour IsLiked / IsWishedList)
    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID
        FROM Users
        WHERE PublicID = v_UserPublicID
        LIMIT 1;
    END IF;

    SELECT Name
    INTO v_Name
    FROM Products
    WHERE ProductID = v_ProductID;

    IF v_Name IS NULL THEN

        SET v_Message = 'Produit introuvable.';

    ELSE

        SET v_FirstWord = TRIM(
            SUBSTRING_INDEX(v_Name, ' ', 1)
        );

        SET v_Success = TRUE;
        SET v_Message = 'OK';

        WITH ActivePromotions AS (
            SELECT
                p.TargetProductID,
                pt.Code           AS PromotionCode,
                p.DiscountValue   AS PromotionDiscountValue,
                ROW_NUMBER() OVER (
                    PARTITION BY p.TargetProductID
                    ORDER BY p.EndDate ASC
                ) AS rn
            FROM Promotions p
            INNER JOIN PromotionDiscountTypes pt ON pt.DiscountTypeID = p.DiscountTypeID
            WHERE p.ScopeTypeID = 1
              AND p.StatusID = 2
              AND p.IsActive = 1
              AND NOW() BETWEEN p.StartDate AND p.EndDate
              AND p.UsageCount < p.UsageLimitTotal
        )

        SELECT
            p.ProductID                       AS ProductID,
            p.Name                            AS ProductName,
            pr.ResourcesPath                  AS ProductDefaultImage,
            p.Description                     AS Description,
            p.BasePrice                       AS DefaultPrice,
            IFNULL(b.Name, 'No Brand')        AS BrandName,
            IFNULL(b.LogoURL, NULL)               AS BrandLogo,
            IFNULL(m.Name, 'No Model')        AS ModelName,

            (
                SELECT COUNT(*)
                FROM WishListItems wli
                WHERE wli.ProductID = p.ProductID
            ) AS TotalWishlist,

            (
                SELECT COUNT(*)
                FROM ProductLikes pl
                WHERE pl.ProductID = p.ProductID
            ) AS TotalLikes,

            (
                SELECT COUNT(*)
                FROM OrderItems o
                WHERE o.ProductID = p.ProductID
            ) AS TotalOrders,

           CASE
                WHEN v_UserID IS NOT NULL AND EXISTS (
                    SELECT 1 FROM ProductLikes pl2
                    WHERE pl2.ProductID = p.ProductID AND pl2.UserID = v_UserID
                ) THEN 1 ELSE 0
            END AS IsLiked,
            CASE
                WHEN v_UserID IS NOT NULL AND EXISTS (
                    SELECT 1 FROM WishListItems w2
                    INNER JOIN WishLists wq ON wq.WishListID = w2.WishListID
                    WHERE w2.ProductID = p.ProductID AND wq.UserID = v_UserID
                ) THEN 1 ELSE 0
            END AS IsWishedList,

            IF(ap.TargetProductID IS NOT NULL, 1, 0) AS HasPromo,
            ap.PromotionCode                          AS PromotionCode,
            ap.PromotionDiscountValue                 AS PromotionDiscountValue

        FROM Products p

        LEFT JOIN Brands b
            ON b.BrandID = p.BrandID

        LEFT JOIN Models m
            ON m.ModelID = p.ModelID

        LEFT JOIN ProductResources pr
            ON pr.ProductID = p.ProductID
            AND pr.ResourceRoleID = 2

        LEFT JOIN ActivePromotions ap
            ON ap.TargetProductID = p.ProductID
            AND ap.rn = 1

        WHERE p.Name LIKE CONCAT(v_FirstWord, '%')
          AND p.ProductID != v_ProductID

        ORDER BY
            (
                SELECT COUNT(*)
                FROM OrderItems o
                WHERE o.ProductID = p.ProductID
            ) DESC,

            (
                SELECT COUNT(*)
                FROM ProductLikes pl
                WHERE pl.ProductID = p.ProductID
            ) DESC

        LIMIT v_Limit;

    END IF;

END$$

DELIMITER ;



-- =====================================================================
-- DROP STATEMENT
-- =====================================================================
DROP PROCEDURE IF EXISTS SP_GetSimilarProductsByCategory;

-- =====================================================================
-- SP_GetSimilarProductsByCategory
-- =====================================================================
DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `SP_GetSimilarProductsByCategory`(
    IN v_ProductID      INT,
    IN v_UserPublicID    VARCHAR(64),
    IN v_Limit          INT,
    OUT v_Success        BOOLEAN,
    OUT v_Message        VARCHAR(255)
)
BEGIN
    DECLARE v_CategoryCount INT DEFAULT 0;
    DECLARE v_UserID         INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetSimilarProductsByCategory',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('ProductID', v_ProductID, 'Limit', v_Limit)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits similaires.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_Limit IS NULL OR v_Limit < 1 THEN
        SET v_Limit = 10;
    ELSEIF v_Limit > 50 THEN
        SET v_Limit = 50;
    END IF;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID
        FROM Users
        WHERE PublicID = v_UserPublicID
        LIMIT 1;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = v_ProductID) THEN
        SET v_Message = 'Produit introuvable.';
    ELSE
        SELECT COUNT(*) INTO v_CategoryCount
        FROM ProductCategories
        WHERE ProductID = v_ProductID;

        IF v_CategoryCount = 0 THEN
            SET v_Success = TRUE;
            SET v_Message = 'Ce produit n''a aucune catégorie renseignée.';
            SELECT NULL AS ProductID LIMIT 0;
        ELSE
            SET v_Success = TRUE;
            SET v_Message = 'OK';

            WITH ActivePromotions AS (
                SELECT
                    p.TargetProductID,
                    pt.Code           AS PromotionCode,
                    p.DiscountValue   AS PromotionDiscountValue,
                    ROW_NUMBER() OVER (
                        PARTITION BY p.TargetProductID
                        ORDER BY p.EndDate ASC
                    ) AS rn
                FROM Promotions p
                INNER JOIN PromotionDiscountTypes pt ON pt.DiscountTypeID = p.DiscountTypeID
                WHERE p.ScopeTypeID = 1
                  AND p.StatusID = 2
                  AND p.IsActive = 1
                  AND NOW() BETWEEN p.StartDate AND p.EndDate
                  AND p.UsageCount < p.UsageLimitTotal
            )

            SELECT
                p.ProductID                       AS ProductID,
                p.Name                            AS ProductName,
                pr.ResourcesPath                  AS ProductDefaultImage,
                p.Description                     AS Description,
                p.BasePrice                       AS DefaultPrice,
                IFNULL(b.Name, 'No Brand')        AS BrandName,
                IFNULL(b.LogoURL, NULL)            AS BrandLogo,
                IFNULL(m.Name, 'No Model')        AS ModelName,

                (SELECT COUNT(*) FROM WishListItems wli WHERE wli.ProductID = p.ProductID) AS TotalWishlist,
                (SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID) AS TotalLikes,
                (SELECT COUNT(*) FROM OrderItems o WHERE o.ProductID = p.ProductID) AS TotalOrders,

                CASE
                    WHEN v_UserID IS NOT NULL AND EXISTS (
                        SELECT 1 FROM ProductLikes pl2
                        WHERE pl2.ProductID = p.ProductID AND pl2.UserID = v_UserID
                    ) THEN 1 ELSE 0
                END AS IsLiked,
                CASE
                    WHEN v_UserID IS NOT NULL AND EXISTS (
                        SELECT 1 FROM WishListItems w2
                        INNER JOIN WishLists wq ON wq.WishListID = w2.WishListID
                        WHERE w2.ProductID = p.ProductID AND wq.UserID = v_UserID
                    ) THEN 1 ELSE 0
                END AS IsWishedList,

                IF(ap.TargetProductID IS NOT NULL, 1, 0) AS HasPromo,
                ap.PromotionCode                          AS PromotionCode,
                ap.PromotionDiscountValue                 AS PromotionDiscountValue,

                COUNT(DISTINCT pc.CategoryID) AS SharedCategoriesCount

            FROM Products p
            INNER JOIN ProductCategories pc ON pc.ProductID = p.ProductID
            LEFT JOIN Brands b ON b.BrandID = p.BrandID
            LEFT JOIN Models m ON m.ModelID = p.ModelID
            LEFT JOIN ProductResources pr
                ON pr.ProductID = p.ProductID
                AND pr.ResourceRoleID = 2
            LEFT JOIN ActivePromotions ap
                ON ap.TargetProductID = p.ProductID
                AND ap.rn = 1
            WHERE pc.CategoryID IN (
                    SELECT CategoryID FROM ProductCategories WHERE ProductID = v_ProductID
                  )
              AND p.ProductID != v_ProductID
            GROUP BY
                p.ProductID, p.Name, p.Description, p.BasePrice,
                b.Name, b.LogoURL, m.Name, pr.ResourcesPath,
                ap.TargetProductID, ap.PromotionCode, ap.PromotionDiscountValue,
                v_UserID
            ORDER BY
                -- Plus un produit partage de catégories avec le produit de référence,
                -- plus il est considéré similaire (ex: 2 catégories communes > 1 seule).
                SharedCategoriesCount DESC,
                (SELECT COUNT(*) FROM OrderItems o WHERE o.ProductID = p.ProductID) DESC,
                (SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID) DESC
            LIMIT v_Limit;
        END IF;
    END IF;
END$$

DELIMITER ;