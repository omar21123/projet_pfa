DELIMITER $$

CREATE PROCEDURE SP_CreateTag(
    IN p_Name VARCHAR(100),
    IN p_Color VARCHAR(20),
    IN p_Description VARCHAR(255)
)
BEGIN
    DECLARE v_TagID INT;
    DECLARE v_NormalizedText VARCHAR(255);
    DECLARE v_ExistingTagCount INT DEFAULT 0;
    DECLARE v_ExistingSearchCount INT DEFAULT 0;

    -- rollback and re-throw on any unexpected SQL error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET v_NormalizedText = LOWER(TRIM(p_Name));

    -- duplicate tag name check (mirrors Tags.Name UNI constraint)
    SELECT COUNT(*) INTO v_ExistingTagCount
    FROM Tags
    WHERE Name = p_Name;

    IF v_ExistingTagCount > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Un tag avec ce nom existe déjà.';
    END IF;

    START TRANSACTION;

    INSERT INTO Tags (Name, Color, Description)
    VALUES (p_Name, p_Color, p_Description);

    SET v_TagID = LAST_INSERT_ID();

    -- SearchDictionary.NormalizedText is UNI, so check before inserting —
    -- if the same normalized text already exists (e.g. previously indexed
    -- from another source), re-point it at this tag instead of failing.
    SELECT COUNT(*) INTO v_ExistingSearchCount
    FROM SearchDictionary
    WHERE NormalizedText = v_NormalizedText;

    IF v_ExistingSearchCount > 0 THEN
        UPDATE SearchDictionary
        SET
            DisplayText = p_Name,
            SourceType = 2,       -- 2 = Tag (see note below)
            SourceID = v_TagID,
            IsActive = 1,
            UpdatedAt = NOW()
        WHERE NormalizedText = v_NormalizedText;
    ELSE
        INSERT INTO SearchDictionary (
            DisplayText,
            NormalizedText,
            SourceType,
            SourceID
        ) VALUES (
            p_Name,
            v_NormalizedText,
            2,                    -- 2 = Tag (see note below)
            v_TagID
        );
    END IF;

    COMMIT;

    SELECT * FROM Tags WHERE TagID = v_TagID;
END$$

DELIMITER ;


DELIMITER $$

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
        ROLLBACK;
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

    START TRANSACTION;

    INSERT INTO Tags (Name) VALUES (p_Name);

    SET p_TagID = LAST_INSERT_ID();

    SELECT COUNT(*) INTO v_ExistingSearchCount
    FROM SearchDictionary
    WHERE NormalizedText = v_NormalizedText;

    IF v_ExistingSearchCount > 0 THEN
        UPDATE SearchDictionary
        SET
            DisplayText = p_Name,
            SourceType = 2,       -- 2 = Tag (same mapping as SP_CreateTag)
            SourceID = p_TagID,
            IsActive = 1,
            UpdatedAt = NOW()
        WHERE NormalizedText = v_NormalizedText;
    ELSE
        INSERT INTO SearchDictionary (
            DisplayText,
            NormalizedText,
            SourceType,
            SourceID
        ) VALUES (
            p_Name,
            v_NormalizedText,
            2,
            p_TagID
        );
    END IF;

    COMMIT;
END$$

DELIMITER ;