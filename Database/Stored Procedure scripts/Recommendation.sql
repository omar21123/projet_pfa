DELIMITER $$
CREATE PROCEDURE SP_GetMostSoldProducts (
    IN v_UserPublicID VARCHAR(36),
    IN v_Limit         INT,
    IN v_CategoryID    INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetMostSoldProducts',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('UserPublicID', v_UserPublicID, 'Limit', v_Limit, 'CategoryID', v_CategoryID)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits les plus vendus.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_Limit IS NULL OR v_Limit < 1 THEN
        SET v_Limit = 20;
    ELSEIF v_Limit > 100 THEN
        SET v_Limit = 100;
    END IF;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    WITH ProductSales AS (
        SELECT
            oi.ProductID,
            COUNT(*) AS TotalSales
        FROM OrderItems oi
        INNER JOIN Orders o
            ON o.OrderID = oi.OrderID
        WHERE o.OrderStatusID IN (2, 3, 4)
        GROUP BY oi.ProductID
    )
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
        END AS IsWishedList
    FROM Products p
    LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND (pr.ResourceRoleID = 2)
    LEFT JOIN Brands b ON b.BrandID = p.BrandID
    LEFT JOIN Models m ON m.ModelID = p.ModelID
    INNER JOIN ProductSales ps ON ps.ProductID = p.ProductID
    WHERE v_CategoryID IS NULL OR EXISTS (
        SELECT 1 FROM ProductCategories pc
        WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
    )
    ORDER BY ps.TotalSales DESC
    LIMIT v_Limit;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_GetMostViewedProducts (
    IN v_UserPublicID VARCHAR(36),
    IN v_Limit         INT,
    IN v_CategoryID    INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetMostViewedProducts',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('UserPublicID', v_UserPublicID, 'Limit', v_Limit, 'CategoryID', v_CategoryID)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits les plus vus.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_Limit IS NULL OR v_Limit < 1 THEN
        SET v_Limit = 20;
    ELSEIF v_Limit > 100 THEN
        SET v_Limit = 100;
    END IF;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    WITH ProductViews AS (
        SELECT
            ProductID,
            SUM(ViewCount) AS TotalViews
        FROM RegionalProductStats
        GROUP BY ProductID
    )
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
        END AS IsWishedList
    FROM Products p
    LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND (pr.ResourceRoleID = 2)
    LEFT JOIN Brands b ON b.BrandID = p.BrandID
    LEFT JOIN Models m ON m.ModelID = p.ModelID
    INNER JOIN ProductViews pv ON pv.ProductID = p.ProductID
    WHERE v_CategoryID IS NULL OR EXISTS (
        SELECT 1 FROM ProductCategories pc
        WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
    )
    ORDER BY pv.TotalViews DESC
    LIMIT v_Limit;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_GetMostPromotedProducts (
    IN  v_UserPublicID VARCHAR(36),
    IN  v_Limit        INT,
    IN  v_CategoryID   INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetMostPromotedProducts',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('UserPublicID', v_UserPublicID, 'Limit', v_Limit, 'CategoryID', v_CategoryID)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits les plus promus.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_Limit IS NULL OR v_Limit < 1 THEN
        SET v_Limit = 20;
    ELSEIF v_Limit > 100 THEN
        SET v_Limit = 100;
    END IF;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    WITH ActivePromotions AS (
        SELECT
            TargetProductID
        FROM Promotions
        WHERE NOW() BETWEEN StartDate AND EndDate
          AND UsageCount < UsageLimitTotal
          AND ScopeTypeID = 1
          AND StatusID    = 2
          AND IsActive    = 1
          AND DeletedAt   IS NULL
    )
    SELECT
        p.ProductID,
        p.Name                                                                              AS ProductName,
        pr.ResourcesPath                                                                    AS ProductDefaultImage,
        p.Description,
        p.BasePrice                                                                         AS DefaultPrice,
        b.Name                                                                              AS BrandName,
        b.LogoURL                                                                           AS BrandLogo,
        m.Name                                                                              AS ModelName,
        IFNULL((SELECT COUNT(*) FROM WishListItems w  WHERE w.ProductID  = p.ProductID), 0) AS TotalWishlist,
        IFNULL((SELECT COUNT(*) FROM ProductLikes  pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
        IFNULL((SELECT COUNT(*) FROM OrderItems    oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
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
        END AS IsWishedList
    FROM Products p
    LEFT JOIN  ProductResources pr ON pr.ProductID = p.ProductID AND pr.ResourceRoleID = 2
    LEFT JOIN  Brands           b  ON b.BrandID    = p.BrandID
    LEFT JOIN  Models           m  ON m.ModelID    = p.ModelID
    INNER JOIN ActivePromotions ap ON ap.TargetProductID = p.ProductID
    WHERE v_CategoryID IS NULL OR EXISTS (
        SELECT 1 FROM ProductCategories pc
        WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
    )
    LIMIT v_Limit;

END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE SP_GetTrendingProducts (
    IN  v_UserPublicID VARCHAR(36),
    IN  v_Limit        INT,
    IN  v_CategoryID   INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetTrendingProducts',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('UserPublicID', v_UserPublicID, 'Limit', v_Limit, 'CategoryID', v_CategoryID)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits tendance.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_Limit IS NULL OR v_Limit < 1 THEN
        SET v_Limit = 20;
    ELSEIF v_Limit > 100 THEN
        SET v_Limit = 100;
    END IF;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    WITH TrendingScore AS (
        SELECT
            ProductID,
            COUNT(*) AS Total
        FROM (
            SELECT ProductID FROM WishListItems
            UNION ALL
            SELECT ProductID FROM ProductLikes
        ) AS Combined
        GROUP BY ProductID
    )
    SELECT
        p.ProductID,
        p.Name                                                                               AS ProductName,
        pr.ResourcesPath                                                                     AS ProductDefaultImage,
        p.Description,
        p.BasePrice                                                                          AS DefaultPrice,
        b.Name                                                                               AS BrandName,
        b.LogoURL                                                                            AS BrandLogo,
        m.Name                                                                               AS ModelName,
        IFNULL((SELECT COUNT(*) FROM WishListItems w  WHERE w.ProductID  = p.ProductID), 0) AS TotalWishlist,
        IFNULL((SELECT COUNT(*) FROM ProductLikes  pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
        IFNULL((SELECT COUNT(*) FROM OrderItems    oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
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
        END AS IsWishedList
    FROM Products p
    LEFT JOIN  ProductResources pr ON pr.ProductID = p.ProductID AND pr.ResourceRoleID = 2
    LEFT JOIN  Brands           b  ON b.BrandID    = p.BrandID
    LEFT JOIN  Models           m  ON m.ModelID    = p.ModelID
    INNER JOIN TrendingScore    ts ON ts.ProductID = p.ProductID
    WHERE v_CategoryID IS NULL OR EXISTS (
        SELECT 1 FROM ProductCategories pc
        WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
    )
    ORDER BY ts.Total DESC
    LIMIT v_Limit;

END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE SP_GetLastActivityProducts (
    IN  v_UserPublicID VARCHAR(36),
    IN  v_IPAddress    VARCHAR(45),
    IN  v_Limit        INT,
    IN  v_CategoryID   INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetLastActivityProducts',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'UserPublicID', v_UserPublicID,
                'IPAddress',    v_IPAddress,
                'Limit',        v_Limit,
                'CategoryID',   v_CategoryID
            )
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits de la dernière activité.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_Limit IS NULL OR v_Limit < 1 THEN
        SET v_Limit = 20;
    ELSEIF v_Limit > 100 THEN
        SET v_Limit = 100;
    END IF;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    WITH RecentSearches AS (
        SELECT SearchTermID
        FROM UserSearchHistory
        WHERE (v_UserID IS NULL     AND IPAddress = v_IPAddress)
           OR (v_UserID IS NOT NULL AND UserID    = v_UserID)
        ORDER BY SearchedAt DESC
        LIMIT 5
    )
    SELECT
        p.ProductID,
        p.Name                                                                               AS ProductName,
        pr.ResourcesPath                                                                     AS ProductDefaultImage,
        p.Description,
        p.BasePrice                                                                          AS DefaultPrice,
        b.Name                                                                               AS BrandName,
        b.LogoURL                                                                            AS BrandLogo,
        m.Name                                                                               AS ModelName,
        IFNULL((SELECT COUNT(*) FROM WishListItems w  WHERE w.ProductID  = p.ProductID), 0) AS TotalWishlist,
        IFNULL((SELECT COUNT(*) FROM ProductLikes  pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
        IFNULL((SELECT COUNT(*) FROM OrderItems    oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
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
        END AS IsWishedList
    FROM SearchTermProductStats stps
    JOIN  Products             p  ON p.ProductID  = stps.ProductID
    LEFT JOIN ProductResources pr ON pr.ProductID  = p.ProductID AND pr.ResourceRoleID = 2
    LEFT JOIN Brands           b  ON b.BrandID     = p.BrandID
    LEFT JOIN Models           m  ON m.ModelID     = p.ModelID
    WHERE stps.SearchTermID IN (SELECT SearchTermID FROM RecentSearches)
      AND (
          v_CategoryID IS NULL OR EXISTS (
              SELECT 1 FROM ProductCategories pc
              WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
          )
      )
    ORDER BY stps.PurchaseCount DESC, stps.ClickCount DESC
    LIMIT v_Limit;

END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_GetPopularInYourRegion (
    IN  v_UserPublicID VARCHAR(36),
    IN  v_CountryCode  VARCHAR(10),
    IN  v_Region       VARCHAR(100),
    IN  v_Limit        INT,
    IN  v_CategoryID   INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetPopularInYourRegion',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'UserPublicID', v_UserPublicID,
                'CountryCode',  v_CountryCode,
                'Region',       v_Region,
                'Limit',        v_Limit,
                'CategoryID',   v_CategoryID
            )
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits populaires dans votre région.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_Limit IS NULL OR v_Limit < 1 THEN
        SET v_Limit = 20;
    ELSEIF v_Limit > 100 THEN
        SET v_Limit = 100;
    END IF;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    -- If Region is NULL and CountryCode is NULL → return empty
    IF v_CountryCode IS NULL AND v_Region IS NULL THEN
        SET v_Success = TRUE;
        SET v_Message = 'OK';
        SELECT
            NULL AS ProductID,
            NULL AS ProductName,
            NULL AS ProductDefaultImage,
            NULL AS Description,
            NULL AS DefaultPrice,
            NULL AS BrandName,
            NULL AS BrandLogo,
            NULL AS ModelName,
            NULL AS TotalWishlist,
            NULL AS TotalLikes,
            NULL AS TotalOrders,
            NULL AS IsLiked,
            NULL AS IsWishedList,
            NULL AS Score,
            NULL AS Class
        WHERE 1 = 0;

    ELSE

        SET v_Success = TRUE;
        SET v_Message = 'OK';

        WITH RegionalScores AS (
            -- Priority 1 : Region (class 1) — only if v_Region is provided
            SELECT
                ProductID,
                (PurchaseCount * 0.7 + ViewCount * 0.3) AS Score,
                1                                        AS Class
            FROM RegionalProductStats
            WHERE v_Region IS NOT NULL
              AND Region = v_Region

            UNION ALL

            -- Priority 2 : Country (class 2) — only if v_Region is NULL
            SELECT
                ProductID,
                (PurchaseCount * 0.7 + ViewCount * 0.3) AS Score,
                2                                        AS Class
            FROM RegionalProductStats
            WHERE v_Region IS NULL
              AND v_CountryCode IS NOT NULL
              AND CountryCode = v_CountryCode
        )
        SELECT
            p.ProductID,
            p.Name                                                                               AS ProductName,
            pr.ResourcesPath                                                                     AS ProductDefaultImage,
            p.Description,
            p.BasePrice                                                                          AS DefaultPrice,
            b.Name                                                                               AS BrandName,
            b.LogoURL                                                                            AS BrandLogo,
            m.Name                                                                               AS ModelName,
            IFNULL((SELECT COUNT(*) FROM WishListItems w  WHERE w.ProductID  = p.ProductID), 0) AS TotalWishlist,
            IFNULL((SELECT COUNT(*) FROM ProductLikes  pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
            IFNULL((SELECT COUNT(*) FROM OrderItems    oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
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
            rs.Score,
            rs.Class
        FROM Products p
        LEFT JOIN  ProductResources pr ON pr.ProductID = p.ProductID AND pr.ResourceRoleID = 2
        LEFT JOIN  Brands           b  ON b.BrandID    = p.BrandID
        LEFT JOIN  Models           m  ON m.ModelID    = p.ModelID
        INNER JOIN RegionalScores   rs ON rs.ProductID = p.ProductID
        WHERE (
            v_CategoryID IS NULL OR EXISTS (
                SELECT 1 FROM ProductCategories pc
                WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
            )
        )
        ORDER BY rs.Class ASC, rs.Score DESC
        LIMIT v_Limit;

    END IF;

END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_GetNewProducts (
    IN  v_UserPublicID VARCHAR(36),
    IN  v_DaysBack     INT,
    IN  v_Limit        INT,
    IN  v_CategoryID   INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetNewProducts',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'UserPublicID', v_UserPublicID,
                'DaysBack',     v_DaysBack,
                'Limit',        v_Limit,
                'CategoryID',   v_CategoryID
            )
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des nouveaux produits.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_Limit IS NULL OR v_Limit < 1 THEN
        SET v_Limit = 20;
    ELSEIF v_Limit > 100 THEN
        SET v_Limit = 100;
    END IF;

    IF v_DaysBack IS NULL OR v_DaysBack < 1 THEN
        SET v_DaysBack = 7;
    END IF;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    SELECT
        p.ProductID,
        p.Name                                                                               AS ProductName,
        pr.ResourcesPath                                                                     AS ProductDefaultImage,
        p.Description,
        p.BasePrice                                                                          AS DefaultPrice,
        b.Name                                                                               AS BrandName,
        b.LogoURL                                                                            AS BrandLogo,
        m.Name                                                                               AS ModelName,
        IFNULL((SELECT COUNT(*) FROM WishListItems w  WHERE w.ProductID  = p.ProductID), 0) AS TotalWishlist,
        IFNULL((SELECT COUNT(*) FROM ProductLikes  pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
        IFNULL((SELECT COUNT(*) FROM OrderItems    oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
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
        p.CreatedAt
    FROM Products p
    LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND pr.ResourceRoleID = 2
    LEFT JOIN Brands           b  ON b.BrandID    = p.BrandID
    LEFT JOIN Models           m  ON m.ModelID    = p.ModelID
    WHERE p.CreatedAt >= DATE_SUB(NOW(), INTERVAL v_DaysBack DAY)
      AND (
          v_CategoryID IS NULL OR EXISTS (
              SELECT 1 FROM ProductCategories pc
              WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
          )
      )
    ORDER BY p.CreatedAt DESC
    LIMIT v_Limit;

END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_LoadMoreMostSoldProducts (
    IN v_UserPublicID VARCHAR(36),
    IN v_CategoryID    INT,
    IN v_PageNumber    INT,
    IN v_PageSize      INT,
    OUT v_TotalCount   INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
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
            'SP_LoadMoreMostSoldProducts',
            @p_sqlstate, @p_errno, @p_message,
            JSON_OBJECT('UserPublicID', v_UserPublicID, 'CategoryID', v_CategoryID, 'PageNumber', v_PageNumber, 'PageSize', v_PageSize)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits les plus vendus.';
        SET v_TotalCount = 0;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_TotalCount = 0;

    IF v_PageNumber IS NULL OR v_PageNumber < 1 THEN SET v_PageNumber = 1; END IF;
    IF v_PageSize IS NULL OR v_PageSize < 1 THEN
        SET v_PageSize = 20;
    ELSEIF v_PageSize > 100 THEN
        SET v_PageSize = 100;
    END IF;
    SET v_Offset = (v_PageNumber - 1) * v_PageSize;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    -- Compte total (indépendant de la pagination)
    SELECT COUNT(*) INTO v_TotalCount
    FROM (
        SELECT oi.ProductID
        FROM OrderItems oi
        INNER JOIN Orders o ON o.OrderID = oi.OrderID
        WHERE o.OrderStatusID IN (2, 3, 4)
        GROUP BY oi.ProductID
    ) ps_count
    INNER JOIN Products p2 ON p2.ProductID = ps_count.ProductID
    WHERE v_CategoryID IS NULL OR EXISTS (
        SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p2.ProductID AND pc.CategoryID = v_CategoryID
    );

    WITH ProductSales AS (
        SELECT oi.ProductID, COUNT(*) AS TotalSales
        FROM OrderItems oi
        INNER JOIN Orders o ON o.OrderID = oi.OrderID
        WHERE o.OrderStatusID IN (2, 3, 4)
        GROUP BY oi.ProductID
    )
    SELECT
        p.ProductID, p.Name AS ProductName, pr.ResourcesPath AS ProductDefaultImage,
        p.Description, p.BasePrice AS DefaultPrice, b.Name AS BrandName, b.LogoURL AS BrandLogo,
        m.Name AS ModelName,
        IFNULL((SELECT COUNT(*) FROM WishListItems w WHERE w.ProductID = p.ProductID), 0) AS TotalWishlist,
        IFNULL((SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
        IFNULL((SELECT COUNT(*) FROM OrderItems oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
        CASE WHEN v_UserID IS NOT NULL AND EXISTS (
            SELECT 1 FROM ProductLikes pl2 WHERE pl2.ProductID = p.ProductID AND pl2.UserID = v_UserID
        ) THEN 1 ELSE 0 END AS IsLiked,
        CASE WHEN v_UserID IS NOT NULL AND EXISTS (
            SELECT 1 FROM WishListItems w2
            INNER JOIN WishLists wq ON wq.WishListID = w2.WishListID
            WHERE w2.ProductID = p.ProductID AND wq.UserID = v_UserID
        ) THEN 1 ELSE 0 END AS IsWishedList
    FROM Products p
    LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND (pr.ResourceRoleID = 2)
    LEFT JOIN Brands b ON b.BrandID = p.BrandID
    LEFT JOIN Models m ON m.ModelID = p.ModelID
    INNER JOIN ProductSales ps ON ps.ProductID = p.ProductID
    WHERE v_CategoryID IS NULL OR EXISTS (
        SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
    )
    ORDER BY ps.TotalSales DESC
    LIMIT v_PageSize OFFSET v_Offset;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_LoadMoreMostViewedProducts (
    IN v_UserPublicID VARCHAR(36),
    IN v_CategoryID    INT,
    IN v_PageNumber    INT,
    IN v_PageSize      INT,
    OUT v_TotalCount   INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_Offset INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE, @p_errno = MYSQL_ERRNO, @p_message = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_LoadMoreMostViewedProducts', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID, 'CategoryID', v_CategoryID, 'PageNumber', v_PageNumber, 'PageSize', v_PageSize));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits les plus vus.';
        SET v_TotalCount = 0;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_TotalCount = 0;

    IF v_PageNumber IS NULL OR v_PageNumber < 1 THEN SET v_PageNumber = 1; END IF;
    IF v_PageSize IS NULL OR v_PageSize < 1 THEN
        SET v_PageSize = 20;
    ELSEIF v_PageSize > 100 THEN
        SET v_PageSize = 100;
    END IF;
    SET v_Offset = (v_PageNumber - 1) * v_PageSize;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    SELECT COUNT(*) INTO v_TotalCount
    FROM (
        SELECT ProductID FROM RegionalProductStats GROUP BY ProductID
    ) pv_count
    INNER JOIN Products p2 ON p2.ProductID = pv_count.ProductID
    WHERE v_CategoryID IS NULL OR EXISTS (
        SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p2.ProductID AND pc.CategoryID = v_CategoryID
    );

    WITH ProductViews AS (
        SELECT ProductID, SUM(ViewCount) AS TotalViews
        FROM RegionalProductStats
        GROUP BY ProductID
    )
    SELECT
        p.ProductID, p.Name AS ProductName, pr.ResourcesPath AS ProductDefaultImage,
        p.Description, p.BasePrice AS DefaultPrice, b.Name AS BrandName, b.LogoURL AS BrandLogo,
        m.Name AS ModelName,
        IFNULL((SELECT COUNT(*) FROM WishListItems w WHERE w.ProductID = p.ProductID), 0) AS TotalWishlist,
        IFNULL((SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
        IFNULL((SELECT COUNT(*) FROM OrderItems oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
        CASE WHEN v_UserID IS NOT NULL AND EXISTS (
            SELECT 1 FROM ProductLikes pl2 WHERE pl2.ProductID = p.ProductID AND pl2.UserID = v_UserID
        ) THEN 1 ELSE 0 END AS IsLiked,
        CASE WHEN v_UserID IS NOT NULL AND EXISTS (
            SELECT 1 FROM WishListItems w2
            INNER JOIN WishLists wq ON wq.WishListID = w2.WishListID
            WHERE w2.ProductID = p.ProductID AND wq.UserID = v_UserID
        ) THEN 1 ELSE 0 END AS IsWishedList
    FROM Products p
    LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND (pr.ResourceRoleID = 2)
    LEFT JOIN Brands b ON b.BrandID = p.BrandID
    LEFT JOIN Models m ON m.ModelID = p.ModelID
    INNER JOIN ProductViews pv ON pv.ProductID = p.ProductID
    WHERE v_CategoryID IS NULL OR EXISTS (
        SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
    )
    ORDER BY pv.TotalViews DESC
    LIMIT v_PageSize OFFSET v_Offset;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_LoadMoreMostPromotedProducts (
    IN v_UserPublicID VARCHAR(36),
    IN v_CategoryID    INT,
    IN v_PageNumber    INT,
    IN v_PageSize      INT,
    OUT v_TotalCount   INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_Offset INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE, @p_errno = MYSQL_ERRNO, @p_message = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_LoadMoreMostPromotedProducts', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID, 'CategoryID', v_CategoryID, 'PageNumber', v_PageNumber, 'PageSize', v_PageSize));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits les plus promus.';
        SET v_TotalCount = 0;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_TotalCount = 0;

    IF v_PageNumber IS NULL OR v_PageNumber < 1 THEN SET v_PageNumber = 1; END IF;
    IF v_PageSize IS NULL OR v_PageSize < 1 THEN
        SET v_PageSize = 20;
    ELSEIF v_PageSize > 100 THEN
        SET v_PageSize = 100;
    END IF;
    SET v_Offset = (v_PageNumber - 1) * v_PageSize;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    SELECT COUNT(*) INTO v_TotalCount
    FROM Promotions ap_count
    INNER JOIN Products p2 ON p2.ProductID = ap_count.TargetProductID
    WHERE NOW() BETWEEN ap_count.StartDate AND ap_count.EndDate
      AND ap_count.UsageCount < ap_count.UsageLimitTotal
      AND ap_count.ScopeTypeID = 1
      AND ap_count.StatusID = 2
      AND ap_count.IsActive = 1
      AND ap_count.DeletedAt IS NULL
      AND (v_CategoryID IS NULL OR EXISTS (
          SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p2.ProductID AND pc.CategoryID = v_CategoryID
      ));

    WITH ActivePromotions AS (
        SELECT TargetProductID
        FROM Promotions
        WHERE NOW() BETWEEN StartDate AND EndDate
          AND UsageCount < UsageLimitTotal
          AND ScopeTypeID = 1
          AND StatusID = 2
          AND IsActive = 1
          AND DeletedAt IS NULL
    )
    SELECT
        p.ProductID, p.Name AS ProductName, pr.ResourcesPath AS ProductDefaultImage,
        p.Description, p.BasePrice AS DefaultPrice, b.Name AS BrandName, b.LogoURL AS BrandLogo,
        m.Name AS ModelName,
        IFNULL((SELECT COUNT(*) FROM WishListItems w WHERE w.ProductID = p.ProductID), 0) AS TotalWishlist,
        IFNULL((SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
        IFNULL((SELECT COUNT(*) FROM OrderItems oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
        CASE WHEN v_UserID IS NOT NULL AND EXISTS (
            SELECT 1 FROM ProductLikes pl2 WHERE pl2.ProductID = p.ProductID AND pl2.UserID = v_UserID
        ) THEN 1 ELSE 0 END AS IsLiked,
        CASE WHEN v_UserID IS NOT NULL AND EXISTS (
            SELECT 1 FROM WishListItems w2
            INNER JOIN WishLists wq ON wq.WishListID = w2.WishListID
            WHERE w2.ProductID = p.ProductID AND wq.UserID = v_UserID
        ) THEN 1 ELSE 0 END AS IsWishedList
    FROM Products p
    LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND pr.ResourceRoleID = 2
    LEFT JOIN Brands b ON b.BrandID = p.BrandID
    LEFT JOIN Models m ON m.ModelID = p.ModelID
    INNER JOIN ActivePromotions ap ON ap.TargetProductID = p.ProductID
    WHERE v_CategoryID IS NULL OR EXISTS (
        SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
    )
    LIMIT v_PageSize OFFSET v_Offset;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_LoadMoreTrendingProducts (
    IN v_UserPublicID VARCHAR(36),
    IN v_CategoryID    INT,
    IN v_PageNumber    INT,
    IN v_PageSize      INT,
    OUT v_TotalCount   INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_Offset INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE, @p_errno = MYSQL_ERRNO, @p_message = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_LoadMoreTrendingProducts', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID, 'CategoryID', v_CategoryID, 'PageNumber', v_PageNumber, 'PageSize', v_PageSize));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits tendance.';
        SET v_TotalCount = 0;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_TotalCount = 0;

    IF v_PageNumber IS NULL OR v_PageNumber < 1 THEN SET v_PageNumber = 1; END IF;
    IF v_PageSize IS NULL OR v_PageSize < 1 THEN
        SET v_PageSize = 20;
    ELSEIF v_PageSize > 100 THEN
        SET v_PageSize = 100;
    END IF;
    SET v_Offset = (v_PageNumber - 1) * v_PageSize;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    SELECT COUNT(*) INTO v_TotalCount
    FROM (
        SELECT ProductID FROM (
            SELECT ProductID FROM WishListItems
            UNION ALL
            SELECT ProductID FROM ProductLikes
        ) AS Combined_count
        GROUP BY ProductID
    ) ts_count
    INNER JOIN Products p2 ON p2.ProductID = ts_count.ProductID
    WHERE v_CategoryID IS NULL OR EXISTS (
        SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p2.ProductID AND pc.CategoryID = v_CategoryID
    );

    WITH TrendingScore AS (
        SELECT ProductID, COUNT(*) AS Total
        FROM (
            SELECT ProductID FROM WishListItems
            UNION ALL
            SELECT ProductID FROM ProductLikes
        ) AS Combined
        GROUP BY ProductID
    )
    SELECT
        p.ProductID, p.Name AS ProductName, pr.ResourcesPath AS ProductDefaultImage,
        p.Description, p.BasePrice AS DefaultPrice, b.Name AS BrandName, b.LogoURL AS BrandLogo,
        m.Name AS ModelName,
        IFNULL((SELECT COUNT(*) FROM WishListItems w WHERE w.ProductID = p.ProductID), 0) AS TotalWishlist,
        IFNULL((SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
        IFNULL((SELECT COUNT(*) FROM OrderItems oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
        CASE WHEN v_UserID IS NOT NULL AND EXISTS (
            SELECT 1 FROM ProductLikes pl2 WHERE pl2.ProductID = p.ProductID AND pl2.UserID = v_UserID
        ) THEN 1 ELSE 0 END AS IsLiked,
        CASE WHEN v_UserID IS NOT NULL AND EXISTS (
            SELECT 1 FROM WishListItems w2
            INNER JOIN WishLists wq ON wq.WishListID = w2.WishListID
            WHERE w2.ProductID = p.ProductID AND wq.UserID = v_UserID
        ) THEN 1 ELSE 0 END AS IsWishedList
    FROM Products p
    LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND pr.ResourceRoleID = 2
    LEFT JOIN Brands b ON b.BrandID = p.BrandID
    LEFT JOIN Models m ON m.ModelID = p.ModelID
    INNER JOIN TrendingScore ts ON ts.ProductID = p.ProductID
    WHERE v_CategoryID IS NULL OR EXISTS (
        SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
    )
    ORDER BY ts.Total DESC
    LIMIT v_PageSize OFFSET v_Offset;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_LoadMoreLastActivityProducts (
    IN v_UserPublicID VARCHAR(36),
    IN v_IPAddress     VARCHAR(45),
    IN v_CategoryID    INT,
    IN v_PageNumber    INT,
    IN v_PageSize      INT,
    OUT v_TotalCount   INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_Offset INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE, @p_errno = MYSQL_ERRNO, @p_message = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_LoadMoreLastActivityProducts', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID, 'IPAddress', v_IPAddress, 'CategoryID', v_CategoryID, 'PageNumber', v_PageNumber, 'PageSize', v_PageSize));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits de la dernière activité.';
        SET v_TotalCount = 0;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_TotalCount = 0;

    IF v_PageNumber IS NULL OR v_PageNumber < 1 THEN SET v_PageNumber = 1; END IF;
    IF v_PageSize IS NULL OR v_PageSize < 1 THEN
        SET v_PageSize = 20;
    ELSEIF v_PageSize > 100 THEN
        SET v_PageSize = 100;
    END IF;
    SET v_Offset = (v_PageNumber - 1) * v_PageSize;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    WITH RecentSearches AS (
        SELECT SearchTermID
        FROM UserSearchHistory
        WHERE (v_UserID IS NULL AND IPAddress = v_IPAddress)
           OR (v_UserID IS NOT NULL AND UserID = v_UserID)
        ORDER BY SearchedAt DESC
        LIMIT 5
    )
    SELECT COUNT(*) INTO v_TotalCount
    FROM SearchTermProductStats stps_count
    INNER JOIN Products p2 ON p2.ProductID = stps_count.ProductID
    WHERE stps_count.SearchTermID IN (SELECT SearchTermID FROM RecentSearches)
      AND (v_CategoryID IS NULL OR EXISTS (
          SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p2.ProductID AND pc.CategoryID = v_CategoryID
      ));

    WITH RecentSearches AS (
        SELECT SearchTermID
        FROM UserSearchHistory
        WHERE (v_UserID IS NULL AND IPAddress = v_IPAddress)
           OR (v_UserID IS NOT NULL AND UserID = v_UserID)
        ORDER BY SearchedAt DESC
        LIMIT 5
    )
    SELECT
        p.ProductID, p.Name AS ProductName, pr.ResourcesPath AS ProductDefaultImage,
        p.Description, p.BasePrice AS DefaultPrice, b.Name AS BrandName, b.LogoURL AS BrandLogo,
        m.Name AS ModelName,
        IFNULL((SELECT COUNT(*) FROM WishListItems w WHERE w.ProductID = p.ProductID), 0) AS TotalWishlist,
        IFNULL((SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
        IFNULL((SELECT COUNT(*) FROM OrderItems oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
        CASE WHEN v_UserID IS NOT NULL AND EXISTS (
            SELECT 1 FROM ProductLikes pl2 WHERE pl2.ProductID = p.ProductID AND pl2.UserID = v_UserID
        ) THEN 1 ELSE 0 END AS IsLiked,
        CASE WHEN v_UserID IS NOT NULL AND EXISTS (
            SELECT 1 FROM WishListItems w2
            INNER JOIN WishLists wq ON wq.WishListID = w2.WishListID
            WHERE w2.ProductID = p.ProductID AND wq.UserID = v_UserID
        ) THEN 1 ELSE 0 END AS IsWishedList
    FROM SearchTermProductStats stps
    JOIN Products p ON p.ProductID = stps.ProductID
    LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND pr.ResourceRoleID = 2
    LEFT JOIN Brands b ON b.BrandID = p.BrandID
    LEFT JOIN Models m ON m.ModelID = p.ModelID
    WHERE stps.SearchTermID IN (SELECT SearchTermID FROM RecentSearches)
      AND (v_CategoryID IS NULL OR EXISTS (
          SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
      ))
    ORDER BY stps.PurchaseCount DESC, stps.ClickCount DESC
    LIMIT v_PageSize OFFSET v_Offset;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_LoadMorePopularInYourRegion (
    IN v_UserPublicID VARCHAR(36),
    IN v_CountryCode   VARCHAR(10),
    IN v_Region        VARCHAR(100),
    IN v_CategoryID    INT,
    IN v_PageNumber    INT,
    IN v_PageSize      INT,
    OUT v_TotalCount   INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_Offset INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE, @p_errno = MYSQL_ERRNO, @p_message = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_LoadMorePopularInYourRegion', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID, 'CountryCode', v_CountryCode, 'Region', v_Region, 'CategoryID', v_CategoryID, 'PageNumber', v_PageNumber, 'PageSize', v_PageSize));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des produits populaires dans votre région.';
        SET v_TotalCount = 0;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_TotalCount = 0;

    IF v_PageNumber IS NULL OR v_PageNumber < 1 THEN SET v_PageNumber = 1; END IF;
    IF v_PageSize IS NULL OR v_PageSize < 1 THEN
        SET v_PageSize = 20;
    ELSEIF v_PageSize > 100 THEN
        SET v_PageSize = 100;
    END IF;
    SET v_Offset = (v_PageNumber - 1) * v_PageSize;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    IF v_CountryCode IS NULL AND v_Region IS NULL THEN
        SET v_Success = TRUE;
        SET v_Message = 'OK';
        SET v_TotalCount = 0;
        SELECT
            NULL AS ProductID, NULL AS ProductName, NULL AS ProductDefaultImage, NULL AS Description,
            NULL AS DefaultPrice, NULL AS BrandName, NULL AS BrandLogo, NULL AS ModelName,
            NULL AS TotalWishlist, NULL AS TotalLikes, NULL AS TotalOrders,
            NULL AS IsLiked, NULL AS IsWishedList, NULL AS Score, NULL AS Class
        WHERE 1 = 0;
    ELSE
        SET v_Success = TRUE;
        SET v_Message = 'OK';

        SELECT COUNT(*) INTO v_TotalCount
        FROM (
            SELECT ProductID FROM RegionalProductStats WHERE v_Region IS NOT NULL AND Region = v_Region
            UNION ALL
            SELECT ProductID FROM RegionalProductStats WHERE v_Region IS NULL AND v_CountryCode IS NOT NULL AND CountryCode = v_CountryCode
        ) rs_count
        INNER JOIN Products p2 ON p2.ProductID = rs_count.ProductID
        WHERE v_CategoryID IS NULL OR EXISTS (
            SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p2.ProductID AND pc.CategoryID = v_CategoryID
        );

        WITH RegionalScores AS (
            SELECT ProductID, (PurchaseCount * 0.7 + ViewCount * 0.3) AS Score, 1 AS Class
            FROM RegionalProductStats
            WHERE v_Region IS NOT NULL AND Region = v_Region

            UNION ALL

            SELECT ProductID, (PurchaseCount * 0.7 + ViewCount * 0.3) AS Score, 2 AS Class
            FROM RegionalProductStats
            WHERE v_Region IS NULL AND v_CountryCode IS NOT NULL AND CountryCode = v_CountryCode
        )
        SELECT
            p.ProductID, p.Name AS ProductName, pr.ResourcesPath AS ProductDefaultImage,
            p.Description, p.BasePrice AS DefaultPrice, b.Name AS BrandName, b.LogoURL AS BrandLogo,
            m.Name AS ModelName,
            IFNULL((SELECT COUNT(*) FROM WishListItems w WHERE w.ProductID = p.ProductID), 0) AS TotalWishlist,
            IFNULL((SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
            IFNULL((SELECT COUNT(*) FROM OrderItems oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
            CASE WHEN v_UserID IS NOT NULL AND EXISTS (
                SELECT 1 FROM ProductLikes pl2 WHERE pl2.ProductID = p.ProductID AND pl2.UserID = v_UserID
            ) THEN 1 ELSE 0 END AS IsLiked,
            CASE WHEN v_UserID IS NOT NULL AND EXISTS (
                SELECT 1 FROM WishListItems w2
                INNER JOIN WishLists wq ON wq.WishListID = w2.WishListID
                WHERE w2.ProductID = p.ProductID AND wq.UserID = v_UserID
            ) THEN 1 ELSE 0 END AS IsWishedList,
            rs.Score, rs.Class
        FROM Products p
        LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND pr.ResourceRoleID = 2
        LEFT JOIN Brands b ON b.BrandID = p.BrandID
        LEFT JOIN Models m ON m.ModelID = p.ModelID
        INNER JOIN RegionalScores rs ON rs.ProductID = p.ProductID
        WHERE v_CategoryID IS NULL OR EXISTS (
            SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
        )
        ORDER BY rs.Class ASC, rs.Score DESC
        LIMIT v_PageSize OFFSET v_Offset;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_LoadMoreNewProducts (
    IN v_UserPublicID VARCHAR(36),
    IN v_DaysBack      INT,
    IN v_CategoryID    INT,
    IN v_PageNumber    INT,
    IN v_PageSize      INT,
    OUT v_TotalCount   INT,
    OUT v_Success      BOOLEAN,
    OUT v_Message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_Offset INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE, @p_errno = MYSQL_ERRNO, @p_message = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_LoadMoreNewProducts', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID, 'DaysBack', v_DaysBack, 'CategoryID', v_CategoryID, 'PageNumber', v_PageNumber, 'PageSize', v_PageSize));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des nouveaux produits.';
        SET v_TotalCount = 0;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_TotalCount = 0;

    IF v_PageNumber IS NULL OR v_PageNumber < 1 THEN SET v_PageNumber = 1; END IF;
    IF v_PageSize IS NULL OR v_PageSize < 1 THEN
        SET v_PageSize = 20;
    ELSEIF v_PageSize > 100 THEN
        SET v_PageSize = 100;
    END IF;
    SET v_Offset = (v_PageNumber - 1) * v_PageSize;

    IF v_DaysBack IS NULL OR v_DaysBack < 1 THEN SET v_DaysBack = 7; END IF;

    IF v_UserPublicID IS NOT NULL THEN
        SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    SELECT COUNT(*) INTO v_TotalCount
    FROM Products p2
    WHERE p2.CreatedAt >= DATE_SUB(NOW(), INTERVAL v_DaysBack DAY)
      AND (v_CategoryID IS NULL OR EXISTS (
          SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p2.ProductID AND pc.CategoryID = v_CategoryID
      ));

    SELECT
        p.ProductID, p.Name AS ProductName, pr.ResourcesPath AS ProductDefaultImage,
        p.Description, p.BasePrice AS DefaultPrice, b.Name AS BrandName, b.LogoURL AS BrandLogo,
        m.Name AS ModelName,
        IFNULL((SELECT COUNT(*) FROM WishListItems w WHERE w.ProductID = p.ProductID), 0) AS TotalWishlist,
        IFNULL((SELECT COUNT(*) FROM ProductLikes pl WHERE pl.ProductID = p.ProductID), 0) AS TotalLikes,
        IFNULL((SELECT COUNT(*) FROM OrderItems oi WHERE oi.ProductID = p.ProductID), 0) AS TotalOrders,
        CASE WHEN v_UserID IS NOT NULL AND EXISTS (
            SELECT 1 FROM ProductLikes pl2 WHERE pl2.ProductID = p.ProductID AND pl2.UserID = v_UserID
        ) THEN 1 ELSE 0 END AS IsLiked,
        CASE WHEN v_UserID IS NOT NULL AND EXISTS (
            SELECT 1 FROM WishListItems w2
            INNER JOIN WishLists wq ON wq.WishListID = w2.WishListID
            WHERE w2.ProductID = p.ProductID AND wq.UserID = v_UserID
        ) THEN 1 ELSE 0 END AS IsWishedList,
        p.CreatedAt
    FROM Products p
    LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND pr.ResourceRoleID = 2
    LEFT JOIN Brands b ON b.BrandID = p.BrandID
    LEFT JOIN Models m ON m.ModelID = p.ModelID
    WHERE p.CreatedAt >= DATE_SUB(NOW(), INTERVAL v_DaysBack DAY)
      AND (v_CategoryID IS NULL OR EXISTS (
          SELECT 1 FROM ProductCategories pc WHERE pc.ProductID = p.ProductID AND pc.CategoryID = v_CategoryID
      ))
    ORDER BY p.CreatedAt DESC
    LIMIT v_PageSize OFFSET v_Offset;
END$$

DELIMITER ;