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