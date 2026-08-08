DELIMITER $$
CREATE PROCEDURE SP_IncrementRegionalProductViewCount (
    IN v_ProductID   INT,
    IN v_CountryCode CHAR(2),
    IN v_Region      VARCHAR(100),
    OUT v_Success    BOOLEAN,
    OUT v_Message    VARCHAR(255)
)
BEGIN
    DECLARE v_StatID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_IncrementRegionalProductViewCount',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('ProductID', v_ProductID, 'CountryCode', v_CountryCode, 'Region', v_Region)
        );
        -- Même en cas d'erreur SQL imprévue, on ne bloque pas le flux appelant :
        -- l'incident est loggé, mais v_Success reste TRUE pour cette SP auxiliaire.
        SET v_Success = TRUE;
        SET v_Message = 'Statistique régionale non enregistrée suite à une erreur interne (voir logs).';
    END;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    IF v_ProductID IS NULL THEN
        -- ProductID manquant = bug applicatif réel, pas une simple géoloc échouée.
        -- On log l'incident mais on ne bloque toujours pas l'appelant.
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_IncrementRegionalProductViewCount', NULL, NULL, 'ProductID manquant', JSON_OBJECT('CountryCode', v_CountryCode, 'Region', v_Region));
        SET v_Message = 'ProductID manquant — statistique ignorée.';
    ELSEIF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = v_ProductID) THEN
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_IncrementRegionalProductViewCount', NULL, NULL, 'Produit introuvable', JSON_OBJECT('ProductID', v_ProductID));
        SET v_Message = 'Produit introuvable — statistique ignorée.';
    ELSEIF v_CountryCode IS NULL OR v_CountryCode = '' THEN
        -- Géolocalisation échouée : skip silencieux, pas une erreur.
        SET v_Message = 'CountryCode indisponible — statistique ignorée.';
    ELSE
        SELECT RegionalProductStatID INTO v_StatID
        FROM RegionalProductStats
        WHERE ProductID = v_ProductID
          AND CountryCode = v_CountryCode
          AND Region <=> v_Region
        LIMIT 1;

        IF v_StatID IS NOT NULL THEN
            UPDATE RegionalProductStats
            SET ViewCount     = ViewCount + 1,
                LastUpdatedAt = NOW()
            WHERE RegionalProductStatID = v_StatID;
        ELSE
            INSERT INTO RegionalProductStats
                (CountryCode, Region, ProductID, ViewCount, PurchaseCount, TrendScore, LastUpdatedAt)
            VALUES
                (v_CountryCode, v_Region, v_ProductID, 1, 0, 0.0000, NOW());
        END IF;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_IncrementRegionalProductPurchaseCount (
    IN v_ProductID   INT,
    IN v_CountryCode CHAR(2),
    IN v_Region      VARCHAR(100),
    OUT v_Success    BOOLEAN,
    OUT v_Message    VARCHAR(255)
)
BEGIN
    DECLARE v_StatID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_IncrementRegionalProductPurchaseCount',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('ProductID', v_ProductID, 'CountryCode', v_CountryCode, 'Region', v_Region)
        );
        SET v_Success = TRUE;
        SET v_Message = 'Statistique régionale non enregistrée suite à une erreur interne (voir logs).';
    END;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    IF v_ProductID IS NULL THEN
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_IncrementRegionalProductPurchaseCount', NULL, NULL, 'ProductID manquant', JSON_OBJECT('CountryCode', v_CountryCode, 'Region', v_Region));
        SET v_Message = 'ProductID manquant — statistique ignorée.';
    ELSEIF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = v_ProductID) THEN
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_IncrementRegionalProductPurchaseCount', NULL, NULL, 'Produit introuvable', JSON_OBJECT('ProductID', v_ProductID));
        SET v_Message = 'Produit introuvable — statistique ignorée.';
    ELSEIF v_CountryCode IS NULL OR v_CountryCode = '' THEN
        SET v_Message = 'CountryCode indisponible — statistique ignorée.';
    ELSE
        SELECT RegionalProductStatID INTO v_StatID
        FROM RegionalProductStats
        WHERE ProductID = v_ProductID
          AND CountryCode = v_CountryCode
          AND Region <=> v_Region
        LIMIT 1;

        IF v_StatID IS NOT NULL THEN
            UPDATE RegionalProductStats
            SET PurchaseCount = PurchaseCount + 1,
                LastUpdatedAt = NOW()
            WHERE RegionalProductStatID = v_StatID;
        ELSE
            INSERT INTO RegionalProductStats
                (CountryCode, Region, ProductID, ViewCount, PurchaseCount, TrendScore, LastUpdatedAt)
            VALUES
                (v_CountryCode, v_Region, v_ProductID, 0, 1, 0.0000, NOW());
        END IF;
    END IF;
END$$

DELIMITER ;