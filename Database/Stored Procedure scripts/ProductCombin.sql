DELIMITER $$

DROP PROCEDURE IF EXISTS SP_CreateProductCombination $$

CREATE PROCEDURE SP_CreateProductCombination (
    IN  p_ProductID       INT,
    IN  p_SKU             VARCHAR(64),
    IN  p_Price           DECIMAL(12,2),
    IN  p_CompareAtPrice  DECIMAL(12,2),
    IN  p_Stock           INT,
    IN  p_ImagePath       VARCHAR(500),
    IN  p_IsDefault       TINYINT,
    IN  p_OptionsJson     JSON,   -- '[{"attributeId":10,"optionId":100},{"attributeId":11,"optionId":201}]'
    OUT p_CombinationID   INT,
    OUT p_Success         TINYINT,
    OUT p_Message         VARCHAR(255)
)
BEGIN
    DECLARE v_OptionsHash   CHAR(64);
    DECLARE v_SortedOptions TEXT;
    DECLARE v_ExistingCount INT DEFAULT 0;
    DECLARE v_i             INT DEFAULT 0;
    DECLARE v_Total         INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_Success = 0;
        SET p_CombinationID = NULL;
        IF p_Message IS NULL OR p_Message = '' THEN
            SET p_Message = 'Une erreur est survenue lors de la création de la combinaison.';
        END IF;
    END;

    IF p_OptionsJson IS NULL OR JSON_LENGTH(p_OptionsJson) = 0 THEN
        SET p_Message = 'Une combinaison doit contenir au moins une option.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Empty combination options';
    END IF;

    SELECT GROUP_CONCAT(
             CONCAT(jt.attributeId, ':', jt.optionId)
             ORDER BY jt.attributeId, jt.optionId SEPARATOR '-'
           )
    INTO v_SortedOptions
    FROM JSON_TABLE(
        p_OptionsJson, '$[*]'
        COLUMNS (
            attributeId INT PATH '$.attributeId',
            optionId    INT PATH '$.optionId'
        )
    ) AS jt;

    SET v_OptionsHash = SHA2(v_SortedOptions, 256);

    SELECT COUNT(*) INTO v_ExistingCount
    FROM ProductOptionsCombiniason
    WHERE ProductID = p_ProductID AND OptionsHash = v_OptionsHash;

    IF v_ExistingCount > 0 THEN
        SET p_Message = 'Cette combinaison d''options existe déjà pour ce produit.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Duplicate combination';
    END IF;

    IF p_IsDefault = 1 THEN
        UPDATE ProductOptionsCombiniason
        SET IsDefault = 0
        WHERE ProductID = p_ProductID AND IsDefault = 1;
    END IF;

    INSERT INTO ProductOptionsCombiniason
        (ProductID, SKU, Price, CompareAtPrice, Stock, ImagePath, OptionsHash, IsDefault)
    VALUES
        (p_ProductID, p_SKU, p_Price, p_CompareAtPrice, IFNULL(p_Stock, 0), p_ImagePath, v_OptionsHash, IFNULL(p_IsDefault, 0));

    SET p_CombinationID = LAST_INSERT_ID();

    SET v_Total = JSON_LENGTH(p_OptionsJson);
    WHILE v_i < v_Total DO
        INSERT INTO ProductOptionsCombiniasonDetails
            (CombinationID, ProductsConfigAttributeID, OptionID)
        VALUES (
            p_CombinationID,
            JSON_UNQUOTE(JSON_EXTRACT(p_OptionsJson, CONCAT('$[', v_i, '].attributeId'))),
            JSON_UNQUOTE(JSON_EXTRACT(p_OptionsJson, CONCAT('$[', v_i, '].optionId')))
        );
        SET v_i = v_i + 1;
    END WHILE;

    SET p_Success = 1;
    SET p_Message = 'Combinaison créée avec succès.';
END $$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_GetProductCombinationsForVendor(
    IN v_UserPublicID VARCHAR(36),
    IN v_ProductID INT
)
BEGIN
    DECLARE v_UserID INT;
    DECLARE v_VendorProfileID INT;
    DECLARE v_ProductExists INT;

    -- Résolution de l'UserID interne à partir de l'ID public
    SELECT UserID INTO v_UserID
    FROM Users
    WHERE UserPublicID = v_UserPublicID;

    IF v_UserID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Utilisateur introuvable';
    END IF;

    -- Résolution du VendorProfileID
    SELECT VendorProfileID INTO v_VendorProfileID
    FROM VendorProfiles
    WHERE UserID = v_UserID;

    IF v_VendorProfileID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Profil vendeur introuvable pour cet utilisateur';
    END IF;

    -- Vérification de propriété du produit
    SELECT COUNT(*) INTO v_ProductExists
    FROM Products
    WHERE ProductID = v_ProductID
      AND VendorID = v_VendorProfileID;

    IF v_ProductExists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Accès refusé : vous n\'êtes pas propriétaire de ce produit';
    END IF;

    -- Retour des combinaisons
    SELECT
        c.CombinationID,
        c.SKU,
        COALESCE(c.Price, pd.BasePrice) AS Price,
        COALESCE(c.Stock, pd.Stock) AS Stock,
        c.ImagePath,
        c.IsDefault,
        pa.Name AS ConfigName,
        o.OptionLabel AS OptionName,
        o.OptionValue AS OptionValue
    FROM ProductOptionsCombiniason c
    INNER JOIN ProductOptionsCombiniasonDetails d ON c.CombinationID = d.CombinationID
    INNER JOIN Products pd ON pd.ProductID = c.ProductID
    INNER JOIN ProductsConfigAttribute pa ON pa.ProductsConfigAttributeID = d.ProductsConfigAttributeID
    INNER JOIN ConfigAttributeOptions o ON o.OptionID = d.OptionID
    WHERE c.IsActive = 1
      AND pa.IsActive = 1
      AND o.IsActive = 1
      AND c.ProductID = v_ProductID;

END$$

DELIMITER ;