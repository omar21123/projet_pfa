-- ============================================================
-- SP_CreateOrder
-- ============================================================
DROP PROCEDURE IF EXISTS SP_CreateOrder;

DELIMITER $$

CREATE PROCEDURE SP_CreateOrder (
    IN  v_PublicID          VARCHAR(64),
    IN  v_AddressID         INT,
    IN  v_PaymentMethodID   INT,
    IN  v_Subtotal          DECIMAL(12,2),
    IN  v_Notes             VARCHAR(255),
    OUT v_OrderID           INT,
    OUT v_OrderNumber       VARCHAR(50),
    OUT v_Success           BOOLEAN,
    OUT v_Message           VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_UserID              INT DEFAULT NULL;
    DECLARE v_PaymentMethodExists INT DEFAULT 0;
    DECLARE v_AddressExists       INT DEFAULT 0;
    DECLARE v_ShippingFee         DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_Discount            DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_Tax                 DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_Total               DECIMAL(12,2) DEFAULT 0.00;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_CreateOrder',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'PublicID', v_PublicID,
                'AddressID', v_AddressID,
                'PaymentMethodID', v_PaymentMethodID,
                'Subtotal', v_Subtotal
            )
        );

        ROLLBACK;
        SET v_Success   = FALSE;
        SET v_OrderID   = NULL;
        SET v_Message   = 'Une erreur est survenue lors de la création de la commande.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_OrderID = NULL;

    -- Basic input validation
    IF v_Subtotal IS NULL OR v_Subtotal <= 0 THEN
        SET v_Message = 'Le sous-total doit être supérieur à zéro.';
        LEAVE main_block;
    END IF;

    -- 1) Check PaymentMethod exists
    SELECT COUNT(*) INTO v_PaymentMethodExists
    FROM PaymentMethods
    WHERE PaymentMethodID = v_PaymentMethodID;

    IF v_PaymentMethodExists = 0 THEN
        SET v_Message = 'Méthode de paiement invalide.';
        LEAVE main_block;
    END IF;

    -- 2) Resolve PublicID -> UserID
    SELECT UserID INTO v_UserID
    FROM Users
    WHERE PublicID = v_PublicID
    LIMIT 1;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable.';
        LEAVE main_block;
    END IF;

    -- 3) Check address belongs to this user
    SELECT COUNT(*) INTO v_AddressExists
    FROM Addresses
    WHERE UserID = v_UserID AND AddressID = v_AddressID;

    IF v_AddressExists = 0 THEN
        SET v_Message = 'Adresse invalide pour cet utilisateur.';
        LEAVE main_block;
    END IF;

    -- 4) Compute amounts
    SET v_ShippingFee = ROUND(v_Subtotal * 0.10, 2);   -- 10% of Subtotal
    SET v_Total        = v_Subtotal + v_ShippingFee - v_Discount + v_Tax;

    -- 5) Generate a unique OrderNumber (timestamp + random suffix, collision-safe enough for this volume)
    SET v_OrderNumber = CONCAT('ORD-', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'), '-', LPAD(FLOOR(RAND() * 999), 3, '0'));

    START TRANSACTION;

    INSERT INTO Orders (
        UserID, BillingAddressID, ShippingAddressID, OrderStatusID, PaymentMethodID,
        OrderNumber, Subtotal, ShippingFee, Discount, Tax, Total, Currency, Notes
    ) VALUES (
        v_UserID, v_AddressID, v_AddressID, 2, v_PaymentMethodID,
        v_OrderNumber, v_Subtotal, v_ShippingFee, v_Discount, v_Tax, v_Total, 'MAD', v_Notes
    );

    SET v_OrderID = LAST_INSERT_ID();

    COMMIT;

    SET v_Success = TRUE;
    SET v_Message = 'Commande créée avec succès.';
END main_block $$

DELIMITER ;


DROP PROCEDURE IF EXISTS SP_CreateOrderItem;

DELIMITER $$

CREATE PROCEDURE SP_CreateOrderItem (
    IN  v_OrderID         INT,
    IN  v_ProductID       INT,
    IN  v_Quantity        INT,
    IN  v_CombinationID   INT,
    IN  v_PromotionID     INT,
    IN  v_PublicID        VARCHAR(64),
    OUT v_OrderItemID     INT,
    OUT v_Success         BOOLEAN,
    OUT v_Message         VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_CurrentUserID   INT DEFAULT NULL;
    DECLARE v_VendorID        INT DEFAULT NULL;
    DECLARE v_VendorProfileID INT DEFAULT NULL;
    DECLARE v_Price           DECIMAL(12,2) DEFAULT NULL;
    DECLARE v_Stock           INT DEFAULT NULL;
    DECLARE v_OrderExists     INT DEFAULT 0;

    DECLARE v_UnitPrice       DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_TotalPrice      DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_Discount        DECIMAL(12,2) DEFAULT 0.00;

    DECLARE v_UserUsageCount     INT DEFAULT 0;
    DECLARE v_DiscountTypeID     INT DEFAULT NULL;
    DECLARE v_DiscountValue      DECIMAL(12,2) DEFAULT NULL;
    DECLARE v_UsageLimitPerUser  INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_CreateOrderItem',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'OrderID', v_OrderID,
                'ProductID', v_ProductID,
                'Quantity', v_Quantity,
                'CombinationID', v_CombinationID,
                'PromotionID', v_PromotionID,
                'PublicID', v_PublicID
            )
        );

        ROLLBACK;
        SET v_Success     = FALSE;
        SET v_OrderItemID = NULL;
        SET v_Message      = 'Une erreur est survenue lors de l''ajout de l''article à la commande.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_OrderItemID = NULL;

    -- Basic input validation
    IF v_Quantity IS NULL OR v_Quantity <= 0 THEN
        SET v_Message = 'La quantité doit être supérieure à zéro.';
        LEAVE main_block;
    END IF;

    -- 0) Check order exists
    SELECT COUNT(*) INTO v_OrderExists
    FROM Orders
    WHERE OrderID = v_OrderID;

    IF v_OrderExists = 0 THEN
        SET v_Message = 'Commande introuvable.';
        LEAVE main_block;
    END IF;

    -- 1) Resolve current user
    SELECT UserID INTO v_CurrentUserID
    FROM Users
    WHERE PublicID = v_PublicID
    LIMIT 1;

    IF v_CurrentUserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable.';
        LEAVE main_block;
    END IF;

    -- 2) Verify product existence and get VendorID
    SELECT VendorID INTO v_VendorID
    FROM Products
    WHERE ProductID = v_ProductID;

    IF v_VendorID IS NULL THEN
        SET v_Message = 'Produit introuvable.';
        LEAVE main_block;
    END IF;

    -- 3) Resolve price/stock — from the combination if provided, otherwise the base product
    IF v_CombinationID IS NOT NULL THEN
        SELECT Price, Stock INTO v_Price, v_Stock
        FROM ProductOptionsCombiniason
        WHERE CombinationID = v_CombinationID
          AND ProductID = v_ProductID
          AND IsActive = 1;

        IF v_Price IS NULL THEN
            SET v_Message = 'Variante de produit introuvable.';
            LEAVE main_block;
        END IF;
    ELSE
        SELECT BasePrice, Stock INTO v_Price, v_Stock
        FROM Products
        WHERE ProductID = v_ProductID;
    END IF;

    -- 4) Verify quantity against stock
    IF v_Quantity > v_Stock THEN
        SET v_Message = 'Stock insuffisant pour la quantité demandée.';
        LEAVE main_block;
    END IF;

    -- 5) Resolve price (with or without promotion)
    IF v_PromotionID IS NULL THEN
        SET v_UnitPrice  = v_Price;
        SET v_TotalPrice = v_Price * v_Quantity;
        SET v_Discount   = 0.00;
    ELSE
        SELECT COUNT(*) INTO v_UserUsageCount
        FROM PromotionUsages
        WHERE PromotionID = v_PromotionID
          AND UserID = v_CurrentUserID;

        SELECT DiscountTypeID, DiscountValue, UsageLimitPerUser
        INTO v_DiscountTypeID, v_DiscountValue, v_UsageLimitPerUser
        FROM Promotions
        WHERE PromotionID = v_PromotionID
          AND ScopeTypeID = 1
          AND TargetProductID = v_ProductID
          AND StatusID = 2
          AND IsActive = 1
          AND NOW() BETWEEN StartDate AND EndDate
          AND UsageCount < UsageLimitTotal;

        IF v_DiscountTypeID IS NULL THEN
            SET v_Message = 'Promotion invalide, expirée ou non applicable à ce produit.';
            LEAVE main_block;
        END IF;

        IF v_UserUsageCount >= v_UsageLimitPerUser THEN
            SET v_Message = 'Vous avez atteint la limite d''utilisation de cette promotion.';
            LEAVE main_block;
        END IF;

        IF v_DiscountTypeID = 1 THEN
            -- Percent
            SET v_Discount  = ROUND(v_Price * v_DiscountValue / 100, 2);
        ELSEIF v_DiscountTypeID = 2 THEN
            -- Fixed
            SET v_Discount  = v_DiscountValue;
        ELSE
            SET v_Message = 'Type de remise inconnu.';
            LEAVE main_block;
        END IF;

        -- Never let discount push the price below zero
        IF v_Discount > v_Price THEN
            SET v_Discount = v_Price;
        END IF;

        SET v_UnitPrice  = v_Price - v_Discount;
        SET v_TotalPrice = v_UnitPrice * v_Quantity;
    END IF;

    -- 6) Resolve VendorProfile
    SELECT VendorProfileID INTO v_VendorProfileID
    FROM VendorProfiles
    WHERE UserID = v_VendorID
    LIMIT 1;

    IF v_VendorProfileID IS NULL THEN
        SET v_Message = 'Profil vendeur introuvable pour ce produit.';
        LEAVE main_block;
    END IF;

    START TRANSACTION;

    -- 7) Insert order item
    INSERT INTO OrderItems (
        OrderID, ProductID, ProductVariantID, VendorProfileID,
        Quantity, UnitPrice, Discount, Tax, Total
    ) VALUES (
        v_OrderID, v_ProductID, v_CombinationID, v_VendorProfileID,
        v_Quantity, v_UnitPrice, v_Discount, 0, v_TotalPrice
    );

    SET v_OrderItemID = LAST_INSERT_ID();

    -- 8) Record promotion usage, if any
    IF v_PromotionID IS NOT NULL THEN
        INSERT INTO PromotionUsages (
            PromotionID, UserID, OrderID, DiscountAmount, UsedAt
        ) VALUES (
            v_PromotionID, v_CurrentUserID, v_OrderID, v_Discount, NOW()
        );

        UPDATE Promotions
        SET UsageCount = UsageCount + 1,
            UpdatedAt = NOW()
        WHERE PromotionID = v_PromotionID;
    END IF;

    COMMIT;

    SET v_Success = TRUE;
    SET v_Message = 'Article ajouté à la commande avec succès.';
END main_block $$

DELIMITER ;

DROP PROCEDURE IF EXISTS SP_RecalculateOrderTotals;

DELIMITER $$

CREATE PROCEDURE SP_RecalculateOrderTotals (
    IN  v_OrderID   INT,
    OUT v_Success   BOOLEAN,
    OUT v_Message   VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_OrderExists  INT DEFAULT 0;
    DECLARE v_Subtotal     DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_ShippingFee  DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_Discount     DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_Tax          DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_Total        DECIMAL(12,2) DEFAULT 0.00;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_RecalculateOrderTotals',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('OrderID', v_OrderID)
        );

        ROLLBACK;
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors du recalcul du total de la commande.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    SELECT COUNT(*) INTO v_OrderExists FROM Orders WHERE OrderID = v_OrderID;

    IF v_OrderExists = 0 THEN
        SET v_Message = 'Commande introuvable.';
        LEAVE main_block;
    END IF;

    -- Sum item totals/discounts/tax from OrderItems
    SELECT
        IFNULL(SUM(UnitPrice * Quantity), 0.00),
        IFNULL(SUM(Discount * Quantity), 0.00),
        IFNULL(SUM(Tax), 0.00)
    INTO v_Subtotal, v_Discount, v_Tax
    FROM OrderItems
    WHERE OrderID = v_OrderID;

    IF v_Subtotal <= 0 THEN
        SET v_Message = 'La commande ne contient aucun article valide.';
        LEAVE main_block;
    END IF;

    SET v_ShippingFee = ROUND(v_Subtotal * 0.10, 2); -- 10% rule, same as SP_CreateOrder
    SET v_Total       = v_Subtotal + v_ShippingFee - v_Discount + v_Tax;

    START TRANSACTION;

    UPDATE Orders
    SET Subtotal    = v_Subtotal,
        ShippingFee = v_ShippingFee,
        Discount    = v_Discount,
        Tax         = v_Tax,
        Total       = v_Total,
        UpdatedAt   = NOW()
    WHERE OrderID = v_OrderID;

    COMMIT;

    SET v_Success = TRUE;
    SET v_Message = 'Total de la commande recalculé avec succès.';
END main_block $$

DELIMITER ;

DROP PROCEDURE IF EXISTS SP_GetOrderById;

DELIMITER $$

CREATE PROCEDURE SP_GetOrderById (
    IN v_OrderID INT
)
BEGIN
    SELECT
        o.OrderID, o.OrderNumber, o.UserID, o.BillingAddressID, o.ShippingAddressID,
        o.OrderStatusID, o.PaymentMethodID, o.Subtotal, o.ShippingFee, o.Discount,
        o.Tax, o.Total, o.Currency, o.Notes, o.OrderedAt
    FROM Orders o
    WHERE o.OrderID = v_OrderID;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS SP_CreateOrderItem;

DELIMITER $$

CREATE PROCEDURE SP_CreateOrderItem (
    IN  v_OrderID         INT,
    IN  v_ProductID       INT,
    IN  v_Quantity        INT,
    IN  v_CombinationID   INT,
    IN  v_PromotionID     INT,
    IN  v_PublicID        VARCHAR(64),
    OUT v_OrderItemID     INT,
    OUT v_Success         BOOLEAN,
    OUT v_Message         VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_CurrentUserID   INT DEFAULT NULL;
    DECLARE v_VendorID        INT DEFAULT NULL;
    DECLARE v_VendorProfileID INT DEFAULT NULL;
    DECLARE v_Price           DECIMAL(12,2) DEFAULT NULL;
    DECLARE v_Stock           INT DEFAULT NULL;
    DECLARE v_OrderExists     INT DEFAULT 0;

    DECLARE v_UnitPrice       DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_TotalPrice      DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_Discount        DECIMAL(12,2) DEFAULT 0.00;

    DECLARE v_UserUsageCount     INT DEFAULT 0;
    DECLARE v_DiscountTypeID     INT DEFAULT NULL;
    DECLARE v_DiscountValue      DECIMAL(12,2) DEFAULT NULL;
    DECLARE v_UsageLimitPerUser  INT DEFAULT NULL;
    DECLARE v_MinOrderAmount     DECIMAL(12,2) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_CreateOrderItem',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'OrderID', v_OrderID,
                'ProductID', v_ProductID,
                'Quantity', v_Quantity,
                'CombinationID', v_CombinationID,
                'PromotionID', v_PromotionID,
                'PublicID', v_PublicID
            )
        );

        ROLLBACK;
        SET v_Success     = FALSE;
        SET v_OrderItemID = NULL;
        SET v_Message      = 'Une erreur est survenue lors de l''ajout de l''article à la commande.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_OrderItemID = NULL;

    -- Basic input validation
    IF v_Quantity IS NULL OR v_Quantity <= 0 THEN
        SET v_Message = 'La quantité doit être supérieure à zéro.';
        LEAVE main_block;
    END IF;

    -- 0) Check order exists
    SELECT COUNT(*) INTO v_OrderExists
    FROM Orders
    WHERE OrderID = v_OrderID;

    IF v_OrderExists = 0 THEN
        SET v_Message = 'Commande introuvable.';
        LEAVE main_block;
    END IF;

    -- 1) Resolve current user
    SELECT UserID INTO v_CurrentUserID
    FROM Users
    WHERE PublicID = v_PublicID
    LIMIT 1;

    IF v_CurrentUserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable.';
        LEAVE main_block;
    END IF;

    -- 2) Verify product existence and get VendorID
    SELECT VendorID INTO v_VendorID
    FROM Products
    WHERE ProductID = v_ProductID;

    IF v_VendorID IS NULL THEN
        SET v_Message = 'Produit introuvable.';
        LEAVE main_block;
    END IF;

    -- 3) Resolve price/stock — from the combination if provided, otherwise the base product
    IF v_CombinationID IS NOT NULL THEN
        SELECT Price, Stock INTO v_Price, v_Stock
        FROM ProductOptionsCombiniason
        WHERE CombinationID = v_CombinationID
          AND ProductID = v_ProductID
          AND IsActive = 1;

        IF v_Price IS NULL THEN
            SET v_Message = 'Variante de produit introuvable.';
            LEAVE main_block;
        END IF;
    ELSE
        SELECT BasePrice, Stock INTO v_Price, v_Stock
        FROM Products
        WHERE ProductID = v_ProductID;
    END IF;

    -- 4) Verify quantity against stock
    IF v_Quantity > v_Stock THEN
        SET v_Message = 'Stock insuffisant pour la quantité demandée.';
        LEAVE main_block;
    END IF;

    -- 5) Resolve price (with or without promotion)
    IF v_PromotionID IS NULL THEN
        SET v_UnitPrice  = v_Price;
        SET v_TotalPrice = v_Price * v_Quantity;
        SET v_Discount   = 0.00;
    ELSE
        SELECT COUNT(*) INTO v_UserUsageCount
        FROM PromotionUsages
        WHERE PromotionID = v_PromotionID
          AND UserID = v_CurrentUserID;

        -- Fetch the promotion WITHOUT the MinOrderAmount check, so we can
        -- distinguish "promotion doesn't exist / expired / inactive" from
        -- "promotion exists but the order doesn't meet its minimum amount".
        SELECT DiscountTypeID, DiscountValue, UsageLimitPerUser, MinOrderAmount
        INTO v_DiscountTypeID, v_DiscountValue, v_UsageLimitPerUser, v_MinOrderAmount
        FROM Promotions
        WHERE PromotionID = v_PromotionID
          AND ScopeTypeID = 1
          AND TargetProductID = v_ProductID
          AND StatusID = 2
          AND IsActive = 1
          AND NOW() BETWEEN StartDate AND EndDate
          AND UsageCount < UsageLimitTotal;

        IF v_DiscountTypeID IS NULL THEN
            SET v_Message = 'Promotion invalide, expirée ou non applicable à ce produit.';
            LEAVE main_block;
        END IF;

        -- Separate, explicit check for the minimum order amount rule
        IF (v_Price * v_Stock) < v_MinOrderAmount THEN
            SET v_Message = 'Le montant minimum requis pour cette promotion n''est pas atteint.';
            LEAVE main_block;
        END IF;

        IF v_UserUsageCount >= v_UsageLimitPerUser THEN
            SET v_Message = 'Vous avez atteint la limite d''utilisation de cette promotion.';
            LEAVE main_block;
        END IF;

        IF v_DiscountTypeID = 1 THEN
            -- Percent
            SET v_Discount  = ROUND(v_Price * v_DiscountValue / 100, 2);
        ELSEIF v_DiscountTypeID = 2 THEN
            -- Fixed
            SET v_Discount  = v_DiscountValue;
        ELSE
            SET v_Message = 'Type de remise inconnu.';
            LEAVE main_block;
        END IF;

        -- Never let discount push the price below zero
        IF v_Discount > v_Price THEN
            SET v_Discount = v_Price;
        END IF;

        SET v_UnitPrice  = v_Price - v_Discount;
        SET v_TotalPrice = v_UnitPrice * v_Quantity;
    END IF;

    -- 6) Resolve VendorProfile
    SELECT VendorProfileID INTO v_VendorProfileID
    FROM VendorProfiles
    WHERE UserID = v_VendorID
    LIMIT 1;

    IF v_VendorProfileID IS NULL THEN
        SET v_Message = 'Profil vendeur introuvable pour ce produit.';
        LEAVE main_block;
    END IF;

    START TRANSACTION;

    -- 7) Insert order item
    INSERT INTO OrderItems (
        OrderID, ProductID, ProductVariantID, VendorProfileID,
        Quantity, UnitPrice, Discount, Tax, Total
    ) VALUES (
        v_OrderID, v_ProductID, v_CombinationID, v_VendorProfileID,
        v_Quantity, v_UnitPrice, v_Discount, 0, v_TotalPrice
    );

    SET v_OrderItemID = LAST_INSERT_ID();

    -- 8) Record promotion usage, if any
    IF v_PromotionID IS NOT NULL THEN
        INSERT INTO PromotionUsages (
            PromotionID, UserID, OrderID, DiscountAmount, UsedAt
        ) VALUES (
            v_PromotionID, v_CurrentUserID, v_OrderID, v_Discount, NOW()
        );

        UPDATE Promotions
        SET UsageCount = UsageCount + 1,
            UpdatedAt = NOW()
        WHERE PromotionID = v_PromotionID;
    END IF;

    COMMIT;

    SET v_Success = TRUE;
    SET v_Message = 'Article ajouté à la commande avec succès.';
END main_block $$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_GetCustomerOrders (
    IN  p_UserID          INT,
    IN  p_StatusCode        VARCHAR(50),   -- NULL = all statuses
    IN  p_Page                INT,
    IN  p_PerPage               INT,
    OUT v_Success                BOOLEAN,
    OUT v_Message                 VARCHAR(255),
    OUT v_TotalCount                INT
)
BEGIN
    DECLARE v_Offset       INT DEFAULT 0;
    DECLARE v_ErrorMessage VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_GetCustomerOrders', v_ErrorMessage, NOW());

        SET v_Success    = FALSE;
        SET v_Message    = 'Une erreur est survenue lors de la récupération des commandes.';
        SET v_TotalCount = 0;
    END;

    IF p_Page IS NULL OR p_Page < 1 THEN
        SET p_Page = 1;
    END IF;

    IF p_PerPage IS NULL OR p_PerPage < 1 THEN
        SET p_PerPage = 20;
    END IF;

    IF p_PerPage > 100 THEN
        SET p_PerPage = 100;
    END IF;

    SET v_Offset = (p_Page - 1) * p_PerPage;

    -- ------------------------------------------------
    -- Total count
    -- ------------------------------------------------
    SELECT COUNT(*) INTO v_TotalCount
    FROM Orders o
    INNER JOIN OrderStatus os ON os.OrderStatusID = o.OrderStatusID
    WHERE o.UserID = p_UserID
      AND (p_StatusCode IS NULL OR p_StatusCode = '' OR os.Code = p_StatusCode);

    -- ------------------------------------------------
    -- Page of results, newest first
    -- ------------------------------------------------
    SELECT
        o.OrderID,
        o.OrderNumber,
        os.Code AS StatusCode,
        os.Name AS StatusName,

        o.Subtotal,
        o.ShippingFee,
        o.Discount,
        o.Tax,
        o.Total,
        o.Currency,

        (SELECT COUNT(*) FROM OrderItems oi WHERE oi.OrderID = o.OrderID) AS TotalItems,
        (SELECT COUNT(DISTINCT oi.VendorProfileID) FROM OrderItems oi WHERE oi.OrderID = o.OrderID) AS TotalVendors,

        o.OrderedAt,
        o.UpdatedAt

    FROM Orders o
    INNER JOIN OrderStatus os ON os.OrderStatusID = o.OrderStatusID
    WHERE o.UserID = p_UserID
      AND (p_StatusCode IS NULL OR p_StatusCode = '' OR os.Code = p_StatusCode)
    ORDER BY o.OrderedAt DESC
    LIMIT p_PerPage OFFSET v_Offset;

    SET v_Success = TRUE;
    SET v_Message = 'Commandes récupérées avec succès.';
END$$

DELIMITER ;