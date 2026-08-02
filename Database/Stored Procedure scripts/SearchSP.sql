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
            d.DisplayText SearchText,
            MAX(us.SearchedAt)  AS LastSearchedAt,
            COUNT(*)            AS SearchCount
        FROM UserSearchHistory us
        inner join SearchDictionary d on d.SearchTermID = us.SearchTermID
        WHERE us.IPAddress = v_IPAddress
       GROUP BY d.NormalizedText, d.DisplayText
        ORDER BY LastSearchedAt DESC
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
            d.DisplayText SearchText,
            MAX(us.SearchedAt)  AS LastSearchedAt,
            COUNT(*)            AS SearchCount
        FROM UserSearchHistory us
        inner join SearchDictionary d on d.SearchTermID = us.SearchTermID
        WHERE us.UserID = v_UserID
        GROUP BY d.NormalizedText, d.DisplayText
        ORDER BY LastSearchedAt DESC
        LIMIT v_Limit;
    END IF;
END$$

DELIMITER ;



DELIMITER $$

CREATE PROCEDURE SP_SearchProductsByTerm(
    IN v_Query VARCHAR(255),
    IN v_UserPublicID VARCHAR(36),
    IN v_PageNumber INT,
    IN v_PageSize INT,
    OUT v_TotalCount INT,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE v_SearchTermID INT;
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_Offset INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_SearchProductsByTerm',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('Query', v_Query, 'UserPublicID', v_UserPublicID)
        );

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la recherche.';
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

    -- Résolution optionnelle de l'utilisateur (pour IsLiked / IsWishedList)
    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    -- Résolution du terme de recherche
    SELECT SearchTermID INTO v_SearchTermID
    FROM SearchDictionary
    WHERE NormalizedText = LOWER(TRIM(v_Query))
    LIMIT 1;

    IF v_SearchTermID IS NULL THEN
        -- Terme inconnu : pas une erreur, simplement aucun résultat.
        SET v_Success = TRUE;
        SET v_Message = 'Aucun résultat pour ce terme de recherche';
        SET v_TotalCount = 0;

        SELECT NULL AS ProductID LIMIT 0; -- resultset vide, structure cohérente pour le fetch côté PHP
    ELSE
        SET v_Success = TRUE;
        SET v_Message = 'OK';

        SELECT COUNT(*) INTO v_TotalCount
        FROM SearchTermProductStats stps
        WHERE stps.SearchTermID = v_SearchTermID;

        SELECT
            p.ProductID,
            p.Name AS ProductName,
            pr.ResourcesPath AS ProductDefaultImage,
            p.Description,
            p.BasePrice AS DefaultPrice,
            b.Name AS BrandName,
            b.LogoURL AS BrandLogo,
            m.Name AS ModelName,
            IFNULL((SELECT COUNT(*) FROM WishListItems w WHERE w.ProductID = p.ProductID), 0) AS TotalWishlist,
            IFNULL((SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
            IFNULL((SELECT COUNT(*) FROM OrderItems oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
            CASE
                WHEN v_UserID IS NOT NULL AND EXISTS (
                    SELECT 1 FROM ProductLikes pl2
                    WHERE pl2.ProductID = p.ProductID AND pl2.UserID = v_UserID
                ) THEN 1 ELSE 0
            END AS IsLiked,
            CASE
                WHEN v_UserID IS NOT NULL AND EXISTS (
                    SELECT 1 FROM WishListItems w2
                    WHERE w2.ProductID = p.ProductID AND w2.UserID = v_UserID
                ) THEN 1 ELSE 0
            END AS IsWishedList
        FROM SearchTermProductStats stps
        JOIN Products p ON p.ProductID = stps.ProductID
        LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND (pr.ResourceRoleID = 2)
        LEFT JOIN Brands b ON b.BrandID = p.BrandID
        LEFT JOIN Models m ON m.ModelID = p.ModelID
        WHERE stps.SearchTermID = v_SearchTermID
        ORDER BY stps.PurchaseCount DESC, stps.ClickCount DESC
        LIMIT v_PageSize OFFSET v_Offset;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_SearchProductsFullText(
    IN v_Query VARCHAR(255),
    IN v_UserPublicID VARCHAR(36),
    OUT v_TotalCount INT,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_SearchText VARCHAR(255);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_SearchProductsFullText',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('Query', v_Query, 'UserPublicID', v_UserPublicID)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la recherche.';
        SET v_TotalCount = 0;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_TotalCount = 0;

    SET v_SearchText = TRIM(v_Query);

    IF v_SearchText IS NULL OR v_SearchText = '' THEN
        SET v_Success = FALSE;
        SET v_Message = 'Le terme de recherche est requis.';
        SELECT NULL AS ProductID LIMIT 0;
    ELSE
        -- Résolution optionnelle de l'utilisateur (pour IsLiked / IsWishedList)
        IF v_UserPublicID IS NOT NULL THEN
            SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
        END IF;

        SET v_Success = TRUE;
        SET v_Message = 'OK';

        SELECT COUNT(*) INTO v_TotalCount
        FROM ProductSearchIndex ind
        WHERE MATCH(ind.SearchText) AGAINST (v_SearchText IN NATURAL LANGUAGE MODE);

        SELECT
            p.ProductID,
            p.Name AS ProductName,
            pr.ResourcesPath AS ProductDefaultImage,
            p.Description,
            p.BasePrice AS DefaultPrice,
            b.Name AS BrandName,
            b.LogoURL AS BrandLogo,
            m.Name AS ModelName,
            IFNULL((SELECT COUNT(*) FROM WishListItems w WHERE w.ProductID = p.ProductID), 0) AS TotalWishlist,
            IFNULL((SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
            IFNULL((SELECT COUNT(*) FROM OrderItems oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
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
            MATCH(ind.SearchText) AGAINST (v_SearchText IN NATURAL LANGUAGE MODE) AS Relevance
        FROM ProductSearchIndex ind
        JOIN Products p ON p.ProductID = ind.ProductID
        LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND (pr.ResourceRoleID = 2)
        LEFT JOIN Brands b ON b.BrandID = p.BrandID
        LEFT JOIN Models m ON m.ModelID = p.ModelID
        WHERE ind.SearchText LIKE CONCAT('%', v_SearchText, '%')
        ORDER BY Relevance DESC;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_UpsertSearchDictionary (
    IN p_DisplayText VARCHAR(255),
    IN p_SourceType  TINYINT,
    IN p_SourceID    BIGINT,
    IN p_ResultCount INT
)
BEGIN
    DECLARE v_SearchTermID BIGINT DEFAULT NULL;
    DECLARE v_NormalizedText VARCHAR(255);

    SET v_NormalizedText = LOWER(TRIM(p_DisplayText));

    -- Check if it exists
    SELECT SearchTermID INTO v_SearchTermID
    FROM SearchDictionary
    WHERE NormalizedText = v_NormalizedText
    LIMIT 1;

    IF v_SearchTermID IS NOT NULL THEN
        -- Exists -> increment stats
        UPDATE SearchDictionary
        SET SearchHitCount   = SearchHitCount + 1,
            SearchHitCount7d = SearchHitCount7d + 1,
            ResultCount      = p_ResultCount,
            LastSearchedAt   = NOW(),
            IsActive         = 1
        WHERE SearchTermID = v_SearchTermID;

        SELECT v_SearchTermID AS SearchTermID, 'UPDATED' AS Action;
    ELSE
        -- Doesn't exist -> insert new
        INSERT INTO SearchDictionary
            (DisplayText, NormalizedText, SourceType, SourceID, Score,
             SearchHitCount, SearchHitCount7d, ResultCount, LastSearchedAt, IsActive)
        VALUES
            (p_DisplayText, v_NormalizedText, p_SourceType, p_SourceID, 0.0000,
             1, 1, p_ResultCount, NOW(), 1);

        SELECT LAST_INSERT_ID() AS SearchTermID, 'INSERTED' AS Action;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_InsertSearchTermProductStats (
    IN p_SearchTermID INT,
    IN p_ProductID    INT,
    OUT v_Success     BOOLEAN,
    OUT v_Message     VARCHAR(255)
)
BEGIN
    DECLARE v_Exists INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_InsertSearchTermProductStats',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('SearchTermID', p_SearchTermID, 'ProductID', p_ProductID)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de l''initialisation des statistiques.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    -- Vérifie si la paire (SearchTermID, ProductID) existe déjà
    SELECT COUNT(*) INTO v_Exists
    FROM SearchTermProductStats
    WHERE SearchTermID = p_SearchTermID
      AND ProductID = p_ProductID;

    IF v_Exists > 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Cette combinaison SearchTermID / ProductID existe déjà.';
    ELSE
        INSERT INTO SearchTermProductStats
            (SearchTermID, ProductID, ImpressionCount, ClickCount, PurchaseCount,
             ClickThroughRate, ConversionRate, LastInteractionAt)
        VALUES
            (p_SearchTermID, p_ProductID, 0, 0, 0,
             0.00000, 0.00000, NULL);

        SET v_Success = TRUE;
        SET v_Message = 'OK';

        SELECT LAST_INSERT_ID() AS SearchTermProductID;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_UpdateSearchDictionaryResultCount (
    IN p_SearchTermID INT,
    IN p_ResultCount  INT,
    OUT v_Success     BOOLEAN,
    OUT v_Message     VARCHAR(255)
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
            'SP_UpdateSearchDictionaryResultCount',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('SearchTermID', p_SearchTermID, 'ResultCount', p_ResultCount)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la mise à jour du compteur de résultats.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF p_SearchTermID IS NULL THEN
        SET v_Message = 'SearchTermID est requis.';
    ELSE
        UPDATE SearchDictionary
        SET ResultCount = p_ResultCount
        WHERE SearchTermID = p_SearchTermID;

            SET v_Success = TRUE;
            SET v_Message = 'OK';
        END IF;
END$$

DELIMITER ;