DELIMITER $$

CREATE PROCEDURE SP_UpsertSearchTerm(
    IN p_DisplayText VARCHAR(255),
    IN p_SourceType TINYINT,
    IN p_SourceID INT
)
BEGIN
    DECLARE v_NormalizedText VARCHAR(255);
    DECLARE v_ExistingCount INT DEFAULT 0;

    SET v_NormalizedText = LOWER(TRIM(p_DisplayText));

    SELECT COUNT(*) INTO v_ExistingCount
    FROM SearchDictionary
    WHERE NormalizedText = v_NormalizedText;

    IF v_ExistingCount > 0 THEN
        UPDATE SearchDictionary
        SET
            DisplayText = p_DisplayText,
            SourceType = p_SourceType,
            SourceID = p_SourceID,
            IsActive = 1,
            UpdatedAt = NOW()
        WHERE NormalizedText = v_NormalizedText;
    ELSE
        INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
        VALUES (p_DisplayText, v_NormalizedText, p_SourceType, p_SourceID);
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_CreateModel(
    IN p_BrandID INT,
    IN p_Name VARCHAR(150),
    IN p_Code VARCHAR(50),
    IN p_Description TEXT,
    IN p_ReleaseYear SMALLINT,
    OUT p_ModelID INT
)
BEGIN
    DECLARE v_BrandName VARCHAR(150);
    DECLARE v_CountryName VARCHAR(150) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- confirm the brand exists and grab its name + country in one shot
    SELECT b.Name, c.Name
    INTO v_BrandName, v_CountryName
    FROM Brands b
    LEFT JOIN Countries c ON c.CountryID = b.CountryID
    WHERE b.BrandID = p_BrandID;

    IF v_BrandName IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La marque spécifiée n\existe pas.';
    END IF;

    START TRANSACTION;

    INSERT INTO Models (BrandID, Name, Code, Description, ReleaseYear)
    VALUES (p_BrandID, p_Name, p_Code, p_Description, p_ReleaseYear);

    SET p_ModelID = LAST_INSERT_ID();

    -- entry 1: model name only
    CALL SP_UpsertSearchTerm(p_Name, 4, p_ModelID);

    -- entry 2: brand name + model name
    CALL SP_UpsertSearchTerm(CONCAT(v_BrandName, ' ', p_Name), 4, p_ModelID);

    IF v_CountryName IS NOT NULL THEN
        -- entry 3: country + brand name + model name
        CALL SP_UpsertSearchTerm(CONCAT(v_CountryName, ' ', v_BrandName, ' ', p_Name), 4, p_ModelID);

        -- entry 4: country + model name (brand's country)
        CALL SP_UpsertSearchTerm(CONCAT(v_CountryName, ' ', p_Name), 4, p_ModelID);
    END IF;

    COMMIT;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_CreateModelByInfo(
    IN p_BrandID INT,
    IN p_Name VARCHAR(150),
    OUT p_ModelID INT
)
BEGIN
    DECLARE v_BrandName VARCHAR(150);
    DECLARE v_CountryName VARCHAR(150) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT b.Name, c.Name
    INTO v_BrandName, v_CountryName
    FROM Brands b
    LEFT JOIN Countries c ON c.CountryID = b.CountryID
    WHERE b.BrandID = p_BrandID;

    IF v_BrandName IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La marque spécifiée n\existe pas.';
    END IF;

    START TRANSACTION;

    INSERT INTO Models (BrandID, Name) VALUES (p_BrandID, p_Name);

    SET p_ModelID = LAST_INSERT_ID();

    CALL SP_UpsertSearchTerm(p_Name, 4, p_ModelID);
    CALL SP_UpsertSearchTerm(CONCAT(v_BrandName, ' ', p_Name), 4, p_ModelID);

    IF v_CountryName IS NOT NULL THEN
        CALL SP_UpsertSearchTerm(CONCAT(v_CountryName, ' ', v_BrandName, ' ', p_Name), 4, p_ModelID);
        CALL SP_UpsertSearchTerm(CONCAT(v_CountryName, ' ', p_Name), 4, p_ModelID);
    END IF;

    COMMIT;
END$$

DELIMITER ;