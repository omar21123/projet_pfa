DELIMITER $$

CREATE PROCEDURE SP_CreateProductsConfigAttributeByName(
    IN p_Name VARCHAR(150),
    OUT p_AttributeID INT
)
BEGIN
    DECLARE v_NormalizedText VARCHAR(255);
    DECLARE v_ExistingSearchCount INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET v_NormalizedText = LOWER(TRIM(p_Name));

    START TRANSACTION;

    INSERT INTO ProductsConfigAttribute (Name, DisplayOrder)
    VALUES (p_Name, 0);

    SET p_AttributeID = LAST_INSERT_ID();

    SELECT COUNT(*) INTO v_ExistingSearchCount
    FROM SearchDictionary
    WHERE NormalizedText = v_NormalizedText;

    IF v_ExistingSearchCount > 0 THEN
        UPDATE SearchDictionary
        SET
            DisplayText = p_Name,
            SourceType = 4,        -- 4 = ProductsConfigAttribute (confirm real enum)
            SourceID = p_AttributeID,
            IsActive = 1,
            UpdatedAt = NOW()
        WHERE NormalizedText = v_NormalizedText;
    ELSE
        INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
        VALUES (p_Name, v_NormalizedText, 4, p_AttributeID);
    END IF;

    COMMIT;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_CreateProductsConfigAttribute(
    IN p_Name VARCHAR(150),
    IN p_UnitID INT,
    IN p_DisplayOrder INT,
    OUT p_AttributeID INT
)
BEGIN
    DECLARE v_UnitName VARCHAR(150) DEFAULT NULL;
    DECLARE v_NormalizedName VARCHAR(255);
    DECLARE v_DisplayWithUnit VARCHAR(255);
    DECLARE v_NormalizedWithUnit VARCHAR(255);
    DECLARE v_ExistingCount INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- reject unknown UnitID up front rather than silently inserting NULL
    IF p_UnitID IS NOT NULL THEN
        SELECT Name INTO v_UnitName
        FROM Units
        WHERE UnitID = p_UnitID;

        IF v_UnitName IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'L\'unité spécifiée n\'existe pas.';
        END IF;
    END IF;

    SET v_NormalizedName = LOWER(TRIM(p_Name));

    START TRANSACTION;

    INSERT INTO ProductsConfigAttribute (Name, UnitID, DisplayOrder)
    VALUES (p_Name, p_UnitID, IFNULL(p_DisplayOrder, 0));

    SET p_AttributeID = LAST_INSERT_ID();

    -- entry 1: name only
    SELECT COUNT(*) INTO v_ExistingCount
    FROM SearchDictionary
    WHERE NormalizedText = v_NormalizedName;

    IF v_ExistingCount > 0 THEN
        UPDATE SearchDictionary
        SET DisplayText = p_Name, SourceType = 4, SourceID = p_AttributeID, IsActive = 1, UpdatedAt = NOW()
        WHERE NormalizedText = v_NormalizedName;
    ELSE
        INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
        VALUES (p_Name, v_NormalizedName, 4, p_AttributeID);
    END IF;

    -- entry 2: name + unit, only when a unit was given
    IF p_UnitID IS NOT NULL THEN
        SET v_DisplayWithUnit = CONCAT(p_Name, ' ', v_UnitName);
        SET v_NormalizedWithUnit = LOWER(TRIM(v_DisplayWithUnit));

        SET v_ExistingCount = 0;
        SELECT COUNT(*) INTO v_ExistingCount
        FROM SearchDictionary
        WHERE NormalizedText = v_NormalizedWithUnit;

        IF v_ExistingCount > 0 THEN
            UPDATE SearchDictionary
            SET DisplayText = v_DisplayWithUnit, SourceType = 4, SourceID = p_AttributeID, IsActive = 1, UpdatedAt = NOW()
            WHERE NormalizedText = v_NormalizedWithUnit;
        ELSE
            INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
            VALUES (v_DisplayWithUnit, v_NormalizedWithUnit, 4, p_AttributeID);
        END IF;
    END IF;

    COMMIT;
END$$

DELIMITER ;