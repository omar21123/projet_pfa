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
CREATE DEFINER=`root`@`%` PROCEDURE `SP_SearchProductsByTerm`(
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
                    inner join WishLists wq on wq.WishListID = w2.WishListID
                    WHERE w2.ProductID = p.ProductID AND wq.UserID = v_UserID
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
END
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
        WHERE ind.SearchText LIKE CONCAT('%', v_SearchText, '%') and p.IsActive = 1 and p.Status = 2
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


DROP PROCEDURE IF EXISTS SP_RecordSearchTermClick;

DELIMITER $$

CREATE PROCEDURE SP_RecordSearchTermClick(
    IN  p_TermText   VARCHAR(255),
    IN  p_ProductID  INT,
    OUT p_success    TINYINT,
    OUT p_message    VARCHAR(255)
)
BEGIN
    DECLARE v_SearchTermID   INT DEFAULT NULL;
    DECLARE v_ImpressionCount INT DEFAULT 0;
    DECLARE v_ClickCount      INT DEFAULT 0;
    DECLARE v_PurchaseCount   INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_success = 0;
        SET p_message = 'Erreur lors de l''enregistrement du clic.';
    END;

    START TRANSACTION;

    -- Résolution TermText -> SearchTermID
    SELECT SearchTermID INTO v_SearchTermID
    FROM SearchDictionary
    WHERE NormalizedText = LOWER(TRIM(p_TermText))
    LIMIT 1;

    IF v_SearchTermID IS NULL THEN
        ROLLBACK;
        SET p_success = 0;
        SET p_message = 'Terme de recherche introuvable.';
    ELSE
        -- Upsert : incrémente ClickCount si la ligne existe déjà,
        -- sinon la crée avec ClickCount = 1 (clic sans impression connue).
        -- Suppose un index unique sur (SearchTermID, ProductID).
        INSERT INTO SearchTermProductStats (
            SearchTermID, ProductID, ImpressionCount, ClickCount,
            PurchaseCount, ClickThroughRate, ConversionRate, LastInteractionAt
        ) VALUES (
            v_SearchTermID, p_ProductID, 0, 1, 0, 0.00000, 0.00000, NOW()
        )
        ON DUPLICATE KEY UPDATE
            ClickCount        = ClickCount + 1,
            LastInteractionAt = NOW();

        -- Relecture des compteurs à jour pour recalculer les taux
        SELECT ImpressionCount, ClickCount, PurchaseCount
        INTO v_ImpressionCount, v_ClickCount, v_PurchaseCount
        FROM SearchTermProductStats
        WHERE SearchTermID = v_SearchTermID AND ProductID = p_ProductID;

        UPDATE SearchTermProductStats
        SET
            ClickThroughRate = CASE WHEN v_ImpressionCount > 0
                THEN LEAST(v_ClickCount / v_ImpressionCount, 999.99999)
                ELSE 0.00000 END,
            ConversionRate = CASE WHEN v_ClickCount > 0
                THEN LEAST(v_PurchaseCount / v_ClickCount, 999.99999)
                ELSE 0.00000 END
        WHERE SearchTermID = v_SearchTermID AND ProductID = p_ProductID;

        COMMIT;
        SET p_success = 1;
        SET p_message = 'OK';
    END IF;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS SP_RecordSearchTermPurchase;

DELIMITER $$

CREATE PROCEDURE SP_RecordSearchTermPurchase(
    IN  p_TermText   VARCHAR(255),
    IN  p_ProductID  INT,
    OUT p_success    TINYINT,
    OUT p_message    VARCHAR(255)
)
BEGIN
    DECLARE v_SearchTermID    INT DEFAULT NULL;
    DECLARE v_ImpressionCount INT DEFAULT 0;
    DECLARE v_ClickCount      INT DEFAULT 0;
    DECLARE v_PurchaseCount   INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_success = 0;
        SET p_message = 'Erreur lors de l''enregistrement de l''achat.';
    END;

    START TRANSACTION;

    -- Résolution TermText -> SearchTermID
    SELECT SearchTermID INTO v_SearchTermID
    FROM SearchDictionary
    WHERE NormalizedText = LOWER(TRIM(p_TermText))
    LIMIT 1;

    IF v_SearchTermID IS NULL THEN
        ROLLBACK;
        SET p_success = 0;
        SET p_message = 'Terme de recherche introuvable.';
    ELSE
        -- Upsert : incrémente PurchaseCount si la ligne existe déjà,
        -- sinon la crée avec PurchaseCount = 1 (achat sans clic connu).
        -- Suppose un index unique sur (SearchTermID, ProductID).
        INSERT INTO SearchTermProductStats (
            SearchTermID, ProductID, ImpressionCount, ClickCount,
            PurchaseCount, ClickThroughRate, ConversionRate, LastInteractionAt
        ) VALUES (
            v_SearchTermID, p_ProductID, 0, 0, 1, 0.00000, 0.00000, NOW()
        )
        ON DUPLICATE KEY UPDATE
            PurchaseCount     = PurchaseCount + 1,
            LastInteractionAt = NOW();

        -- Relecture des compteurs à jour pour recalculer les taux
        SELECT ImpressionCount, ClickCount, PurchaseCount
        INTO v_ImpressionCount, v_ClickCount, v_PurchaseCount
        FROM SearchTermProductStats
        WHERE SearchTermID = v_SearchTermID AND ProductID = p_ProductID;

        -- Seul ConversionRate dépend de PurchaseCount (PurchaseCount / ClickCount).
        -- ClickThroughRate est inchangé ici (ne dépend pas des achats).
        UPDATE SearchTermProductStats
        SET
            ConversionRate = CASE WHEN v_ClickCount > 0
                THEN LEAST(v_PurchaseCount / v_ClickCount, 999.99999)
                ELSE 0.00000 END
        WHERE SearchTermID = v_SearchTermID AND ProductID = p_ProductID;

        COMMIT;
        SET p_success = 1;
        SET p_message = 'OK';
    END IF;
END$$

DELIMITER ;
DELIMITER $$
CREATE PROCEDURE SP_LogUserSearch (
    IN  v_UserPublicID VARCHAR(36),
    IN  v_SearchTermID INT,
    IN  v_IPAddress    VARCHAR(45),
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID        INT     DEFAULT NULL;
    DECLARE v_AlreadyExists INT     DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_LogUserSearch',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('UserPublicID', v_UserPublicID, 'SearchTermID', v_SearchTermID, 'IPAddress', v_IPAddress)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de l''enregistrement de la recherche.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_SearchTermID IS NULL THEN
        SET v_Message = 'SearchTermID est requis.';
    ELSE

        IF v_UserPublicID IS NOT NULL THEN
            SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
        END IF;

        -- If PublicID was provided but no matching user found, v_UserID stays NULL
        -- In both cases (not provided / not found) → fall back to IP-only

        IF v_UserID IS NOT NULL THEN
            SELECT COUNT(*) INTO v_AlreadyExists
            FROM UserSearchHistory
            WHERE UserID       = v_UserID
              AND SearchTermID = v_SearchTermID;
        ELSE
            SELECT COUNT(*) INTO v_AlreadyExists
            FROM UserSearchHistory
            WHERE UserID      IS NULL
              AND IPAddress    = v_IPAddress
              AND SearchTermID = v_SearchTermID;
        END IF;

        IF v_AlreadyExists > 0 THEN
            SET v_Success = TRUE;
            SET v_Message = 'Recherche déjà enregistrée pour cet utilisateur.';
        ELSE
            INSERT INTO UserSearchHistory (UserID, SearchTermID, IPAddress, SearchedAt)
            VALUES (v_UserID, v_SearchTermID, v_IPAddress, NOW());

            SET v_Success = TRUE;
            SET v_Message = 'OK';
        END IF;

    END IF;

END$$

DELIMITER ;