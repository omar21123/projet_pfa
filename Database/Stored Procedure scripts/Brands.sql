DELIMITER $$

CREATE PROCEDURE SP_CreateBrandByName(
    IN p_Name VARCHAR(150),
    OUT p_BrandID INT
)
BEGIN
    DECLARE v_BaseSlug VARCHAR(150);
    DECLARE v_NormalizedText VARCHAR(255);
    DECLARE v_ExistingSearchCount INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET v_BaseSlug = LOWER(REPLACE(TRIM(p_Name), ' ', '-'));
    SET v_NormalizedText = LOWER(TRIM(p_Name));

    START TRANSACTION;

    -- temp unique slug placeholder to satisfy the UNI constraint,
    -- finalized below once we have the auto-increment ID
    INSERT INTO Brands (Name, Slug)
    VALUES (p_Name, CONCAT(v_BaseSlug, '-', UUID_SHORT()));

    SET p_BrandID = LAST_INSERT_ID();

    UPDATE Brands
    SET Slug = CONCAT(v_BaseSlug, '-', p_BrandID)
    WHERE BrandID = p_BrandID;

    SELECT COUNT(*) INTO v_ExistingSearchCount
    FROM SearchDictionary
    WHERE NormalizedText = v_NormalizedText;

    IF v_ExistingSearchCount > 0 THEN
        UPDATE SearchDictionary
        SET
            DisplayText = p_Name,
            SourceType = 3,        -- 3 = Brand (confirm real enum)
            SourceID = p_BrandID,
            IsActive = 1,
            UpdatedAt = NOW()
        WHERE NormalizedText = v_NormalizedText;
    ELSE
        INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
        VALUES (p_Name, v_NormalizedText, 3, p_BrandID);
    END IF;

    COMMIT;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_CreateBrand(
    IN p_Name VARCHAR(150),
    IN p_LogoURL VARCHAR(500),
    IN p_Website VARCHAR(255),
    IN p_Description TEXT,
    IN p_CountryID INT,
    OUT p_BrandID INT
)
BEGIN
    DECLARE v_BaseSlug VARCHAR(150);
    DECLARE v_CountryName VARCHAR(150) DEFAULT NULL;
    DECLARE v_NormalizedName VARCHAR(255);
    DECLARE v_DisplayWithCountry VARCHAR(255);
    DECLARE v_NormalizedWithCountry VARCHAR(255);
    DECLARE v_ExistingCount INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- reject unknown CountryID up front rather than silently inserting NULL
    IF p_CountryID IS NOT NULL THEN
        SELECT Name INTO v_CountryName
        FROM Countries
        WHERE CountryID = p_CountryID;

        IF v_CountryName IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Le pays spécifié n\existe pas.';
        END IF;
    END IF;

    SET v_BaseSlug = LOWER(REPLACE(TRIM(p_Name), ' ', '-'));
    SET v_NormalizedName = LOWER(TRIM(p_Name));

    START TRANSACTION;

    INSERT INTO Brands (Name, Slug, LogoURL, Website, Description, CountryID)
    VALUES (p_Name, CONCAT(v_BaseSlug, '-', UUID_SHORT()), p_LogoURL, p_Website, p_Description, p_CountryID);

    SET p_BrandID = LAST_INSERT_ID();

    UPDATE Brands
    SET Slug = CONCAT(v_BaseSlug, '-', p_BrandID)
    WHERE BrandID = p_BrandID;

    -- entry 1: name only
    SELECT COUNT(*) INTO v_ExistingCount
    FROM SearchDictionary
    WHERE NormalizedText = v_NormalizedName;

    IF v_ExistingCount > 0 THEN
        UPDATE SearchDictionary
        SET DisplayText = p_Name, SourceType = 3, SourceID = p_BrandID, IsActive = 1, UpdatedAt = NOW()
        WHERE NormalizedText = v_NormalizedName;
    ELSE
        INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
        VALUES (p_Name, v_NormalizedName, 3, p_BrandID);
    END IF;

    -- entry 2: name + country, only when a country was given
    IF p_CountryID IS NOT NULL THEN
        SET v_DisplayWithCountry = CONCAT(p_Name, ' ', v_CountryName);
        SET v_NormalizedWithCountry = LOWER(TRIM(v_DisplayWithCountry));

        SET v_ExistingCount = 0;
        SELECT COUNT(*) INTO v_ExistingCount
        FROM SearchDictionary
        WHERE NormalizedText = v_NormalizedWithCountry;

        IF v_ExistingCount > 0 THEN
            UPDATE SearchDictionary
            SET DisplayText = v_DisplayWithCountry, SourceType = 3, SourceID = p_BrandID, IsActive = 1, UpdatedAt = NOW()
            WHERE NormalizedText = v_NormalizedWithCountry;
        ELSE
            INSERT INTO SearchDictionary (DisplayText, NormalizedText, SourceType, SourceID)
            VALUES (v_DisplayWithCountry, v_NormalizedWithCountry, 3, p_BrandID);
        END IF;
    END IF;

    COMMIT;
END$$

DELIMITER ;