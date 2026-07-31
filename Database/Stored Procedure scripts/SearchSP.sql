DELIMITER $$

CREATE PROCEDURE SP_GetSearchSuggestions(
    IN v_NormalizedQuery VARCHAR(255),
    IN v_Limit INT,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetSearchSuggestions',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('NormalizedQuery', v_NormalizedQuery, 'Limit', v_Limit)
        );

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des suggestions.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_NormalizedQuery IS NULL OR CHAR_LENGTH(TRIM(v_NormalizedQuery)) < 2 THEN
        SET v_Message = 'La requête doit contenir au moins 2 caractères';
    ELSE
        IF v_Limit IS NULL OR v_Limit < 1 THEN
            SET v_Limit = 10;
        ELSEIF v_Limit > 20 THEN
            SET v_Limit = 20;
        END IF;

        SET v_Success = TRUE;
        SET v_Message = 'OK';

        -- Prefix match : utilise l'index sur NormalizedText, rapide même sur une grande table.
        -- Les résultats les plus fréquemment recherchés (7 derniers jours, puis global,
        -- puis nombre de résultats retournés) remontent en premier.
        SELECT DisplayText
        FROM SearchDictionary
        WHERE NormalizedText LIKE CONCAT(v_NormalizedQuery, '%')
        ORDER BY SearchHitCount7d DESC, SearchHitCount DESC, ResultCount DESC
        LIMIT v_Limit;
    END IF;
END$$

DELIMITER ;



DELIMITER $$

CREATE PROCEDURE SP_GetUserLatestSearches(
    IN v_UserID INT,
    IN v_Limit INT,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_GetUserLatestSearches', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserID', v_UserID, 'Limit', v_Limit));

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération de l''historique.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        IF v_Limit IS NULL OR v_Limit < 1 THEN
            SET v_Limit = 10;
        ELSEIF v_Limit > 50 THEN
            SET v_Limit = 50;
        END IF;

        SET v_Success = TRUE;
        SET v_Message = 'OK';

        -- Une occurrence par texte de recherche distinct, la plus récente en premier.
        SELECT
            us.SearchText,
            MAX(us.SearchedAt)  AS LastSearchedAt,
            COUNT(*)            AS SearchCount
        FROM UserSearches us
        WHERE us.UserID = v_UserID
        GROUP BY us.NormalizedText, us.SearchText
        ORDER BY LastSearchedAt DESC
        LIMIT v_Limit;
    END IF;
END$$

CREATE PROCEDURE SP_GetFamousSearchesByIP(
    IN v_IPAddress VARCHAR(45),
    IN v_Limit INT,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_GetFamousSearchesByIP', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('IPAddress', v_IPAddress, 'Limit', v_Limit));

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des recherches populaires.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_IPAddress IS NULL OR v_IPAddress = '' THEN
        SET v_Message = 'Adresse IP invalide';
    ELSE
        IF v_Limit IS NULL OR v_Limit < 1 THEN
            SET v_Limit = 10;
        ELSEIF v_Limit > 50 THEN
            SET v_Limit = 50;
        END IF;

        SET v_Success = TRUE;
        SET v_Message = 'OK';

        -- Recherches les plus fréquentes émises depuis cette IP exacte,
        -- indépendamment de l'utilisateur (couvre aussi les invités).
        SELECT
            us.SearchText,
            COUNT(*)           AS SearchCount,
            MAX(us.SearchedAt) AS LastSearchedAt
        FROM UserSearches us
        WHERE us.IPAddress = v_IPAddress
        GROUP BY us.NormalizedText, us.SearchText
        ORDER BY SearchCount DESC, LastSearchedAt DESC
        LIMIT v_Limit;
    END IF;
END$$

DELIMITER ;


