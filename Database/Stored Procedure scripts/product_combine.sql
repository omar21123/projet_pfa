DELIMITER $$

DROP PROCEDURE IF EXISTS SP_GetProductCombinationByID $$

CREATE PROCEDURE SP_GetProductCombinationByID(
    IN v_UserPublicID VARCHAR(36),
    IN v_CombinationID INT UNSIGNED,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT;
    DECLARE v_CombinationExists INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération de la combinaison.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    -- 1. Résolution simple de l'utilisateur (sans la colonne Role)
    SELECT UserID INTO v_UserID 
    FROM Users 
    WHERE PublicID = v_UserPublicID;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        -- 2. Vérification de l'existence de la combinaison
        SELECT COUNT(*) INTO v_CombinationExists
        FROM ProductOptionsCombiniason
        WHERE CombinationID = v_CombinationID;

        IF v_CombinationExists = 0 THEN
            SET v_Message = 'Combinaison introuvable';
        ELSE
            SET v_Success = TRUE;
            SET v_Message = 'OK';

            -- Resultset 1 : Les infos générales de la combinaison
            SELECT
                c.CombinationID,
                c.ProductID,
                c.SKU,
                c.Price,
                c.CompareAtPrice,
                c.Stock,
                c.ImagePath,
                CAST(IFNULL(c.IsDefault, 0) AS UNSIGNED) AS IsDefault,
                CAST(IFNULL(c.IsActive, 1) AS UNSIGNED) AS IsActive,
                c.CreatedAt,
                c.UpdatedAt
            FROM ProductOptionsCombiniason c
            WHERE c.CombinationID = v_CombinationID;

            -- Resultset 2 : Les détails/options de cette combinaison (avec pa.AttributeID)
            SELECT
                COALESCE(pa.Name, 'Attribut non défini') AS ConfigName,
                COALESCE(o.OptionLabel, 'Valeur non définie') AS OptionName,
                COALESCE(o.OptionValue, '') AS OptionValue
            FROM ProductOptionsCombiniasonDetails d
            LEFT JOIN ProductsConfigAttribute pa ON pa.AttributeID = d.ProductsConfigAttributeID
            LEFT JOIN ConfigAttributeOptions o ON o.OptionID = d.OptionID
            WHERE d.CombinationID = v_CombinationID;
        END IF;
    END IF;
END$$

DELIMITER ;
