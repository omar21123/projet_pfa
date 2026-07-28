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
    WHERE PublicID = v_UserPublicID;

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
        SET MESSAGE_TEXT = 'Accès refusé : vous n\êtes pas propriétaire de ce produit';
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




DELIMITER $$
CREATE PROCEDURE SP_GetProductCombinationByID(
    IN v_UserPublicID VARCHAR(36),
    IN v_CombinationID INT UNSIGNED,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT;
    DECLARE v_VendorProfileID INT;
    DECLARE v_ProductID INT;
    DECLARE v_OwnerVendorID INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération de la combinaison.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    -- Résolution utilisateur
    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        -- Résolution profil vendeur
        SELECT VendorProfileID INTO v_VendorProfileID
        FROM VendorProfiles WHERE UserID = v_UserID;

        IF v_VendorProfileID IS NULL THEN
            SET v_Message = 'Profil vendeur introuvable pour cet utilisateur';
        ELSE
            -- Résolution combinaison -> produit -> vendeur propriétaire
            SELECT c.ProductID, p.VendorID
            INTO v_ProductID, v_OwnerVendorID
            FROM ProductOptionsCombiniason c
            INNER JOIN Products p ON p.ProductID = c.ProductID
            WHERE c.CombinationID = v_CombinationID;

            IF v_ProductID IS NULL THEN
                SET v_Message = 'Combinaison introuvable';
            ELSEIF v_OwnerVendorID <> v_VendorProfileID THEN
                SET v_Message = 'Accès refusé : vous n''êtes pas propriétaire de cette combinaison';
            ELSE
                SET v_Success = TRUE;
                SET v_Message = 'OK';

                -- Resultset 1 : la combinaison
                SELECT
                    c.CombinationID,
                    c.ProductID,
                    c.SKU,
                    c.Price,
                    c.CompareAtPrice,
                    c.Stock,
                    c.ImagePath,
                    CAST(c.IsDefault AS UNSIGNED) AS IsDefault,
                    CAST(c.IsActive AS UNSIGNED) AS IsActive,
                    c.CreatedAt,
                    c.UpdatedAt
                FROM ProductOptionsCombiniason c
                WHERE c.CombinationID = v_CombinationID;

                -- Resultset 2 : les options de cette combinaison
                SELECT
                    pa.Name AS ConfigName,
                    o.OptionLabel AS OptionName,
                    o.OptionValue AS OptionValue
                FROM ProductOptionsCombiniasonDetails d
                INNER JOIN ProductsConfigAttribute pa ON pa.AttributeID = d.ProductsConfigAttributeID
                INNER JOIN ConfigAttributeOptions o ON o.OptionID = d.OptionID
                WHERE d.CombinationID = v_CombinationID;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;

DELIMITER $$
CREATE PROCEDURE SP_UpdateProductCombination(
    IN v_UserPublicID VARCHAR(36),
    IN v_CombinationID INT UNSIGNED,
    IN v_SKU VARCHAR(64),
    IN v_Price DECIMAL(10,2),
    IN v_CompareAtPrice DECIMAL(10,2),
    IN v_Stock INT,
    IN v_ImagePath VARCHAR(255),
    IN v_IsDefault TINYINT(1),
    IN v_IsActive TINYINT(1),
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT;
    DECLARE v_VendorProfileID INT;
    DECLARE v_ProductID INT;
    DECLARE v_OwnerVendorID INT;
    DECLARE v_DuplicateSKU INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la mise à jour de la combinaison.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    -- Résolution utilisateur
    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        -- Résolution profil vendeur
        SELECT VendorProfileID INTO v_VendorProfileID
        FROM VendorProfiles WHERE UserID = v_UserID;

        IF v_VendorProfileID IS NULL THEN
            SET v_Message = 'Profil vendeur introuvable pour cet utilisateur';
        ELSE
            -- Résolution combinaison -> produit -> vendeur propriétaire
            SELECT c.ProductID, p.VendorID
            INTO v_ProductID, v_OwnerVendorID
            FROM ProductOptionsCombiniason c
            INNER JOIN Products p ON p.ProductID = c.ProductID
            WHERE c.CombinationID = v_CombinationID;

            IF v_ProductID IS NULL THEN
                SET v_Message = 'Combinaison introuvable';
            ELSEIF v_OwnerVendorID <> v_VendorProfileID THEN
                SET v_Message = 'Accès refusé : vous n''êtes pas propriétaire de cette combinaison';
            ELSEIF v_Price IS NULL OR v_Price < 0 THEN
                SET v_Message = 'Le prix doit être supérieur ou égal à 0';
            ELSEIF v_Stock IS NULL OR v_Stock < 0 THEN
                SET v_Message = 'Le stock doit être supérieur ou égal à 0';
            ELSEIF v_CompareAtPrice IS NOT NULL AND v_CompareAtPrice < v_Price THEN
                SET v_Message = 'Le prix barré doit être supérieur ou égal au prix';
            ELSE
                -- Unicité du SKU au sein du même produit (hors soi-même)
                IF v_SKU IS NOT NULL THEN
                    SELECT COUNT(*) INTO v_DuplicateSKU
                    FROM ProductOptionsCombiniason
                    WHERE ProductID = v_ProductID
                      AND SKU = v_SKU
                      AND CombinationID <> v_CombinationID;
                ELSE
                    SET v_DuplicateSKU = 0;
                END IF;

                IF v_DuplicateSKU > 0 THEN
                    SET v_Message = 'Ce SKU est déjà utilisé par une autre combinaison de ce produit';
                ELSE
                    START TRANSACTION;

                    -- Si cette combinaison devient la valeur par défaut, désactiver les autres
                    IF v_IsDefault = 1 THEN
                        UPDATE ProductOptionsCombiniason
                        SET IsDefault = b'0'
                        WHERE ProductID = v_ProductID
                          AND CombinationID <> v_CombinationID;
                    END IF;

                    UPDATE ProductOptionsCombiniason
                    SET
                        SKU = v_SKU,
                        Price = v_Price,
                        CompareAtPrice = v_CompareAtPrice,
                        Stock = v_Stock,
                        ImagePath = COALESCE(v_ImagePath, ImagePath),
                        IsDefault = v_IsDefault,
                        IsActive = v_IsActive
                    WHERE CombinationID = v_CombinationID;

                    COMMIT;

                    SET v_Success = TRUE;
                    SET v_Message = 'Combinaison mise à jour avec succès';

                    SELECT
                        c.CombinationID,
                        c.ProductID,
                        c.SKU,
                        c.Price,
                        c.CompareAtPrice,
                        c.Stock,
                        c.ImagePath,
                        CAST(c.IsDefault AS UNSIGNED) AS IsDefault,
                        CAST(c.IsActive AS UNSIGNED) AS IsActive,
                        c.CreatedAt,
                        c.UpdatedAt
                    FROM ProductOptionsCombiniason c
                    WHERE c.CombinationID = v_CombinationID;
                END IF;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;