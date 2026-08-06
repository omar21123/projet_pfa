DELIMITER $$

CREATE PROCEDURE SP_GetMostSoldProducts (
    IN v_UserPublicID VARCHAR(36),
    IN v_Limit         INT,
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
            JSON_OBJECT('UserPublicID', v_UserPublicID, 'Limit', v_Limit)
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

    -- Résolution optionnelle de l'utilisateur (pour IsLiked / IsWishedList).
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
    ORDER BY ps.TotalSales DESC
    LIMIT v_Limit;
END$$

DELIMITER ;