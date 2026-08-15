DROP PROCEDURE IF EXISTS SP_AddOrderItemToDelivery;

DELIMITER $$

CREATE PROCEDURE SP_AddOrderItemToDelivery (
    IN  p_ProductID     INT,
    IN  p_OrderID       INT,
    IN  p_OrderItemID   INT,
    IN  p_AddressToID   INT,
    IN  p_Notes         NVARCHAR(500),
    OUT v_Success       BOOLEAN,
    OUT v_Message       VARCHAR(255),
    OUT v_DeliveryID    INT
)
main_block: BEGIN
    DECLARE v_BasePrice         DECIMAL(10,2);
    DECLARE v_UserID            INT DEFAULT NULL;
    DECLARE v_VendorProfileID   INT DEFAULT NULL;
    DECLARE v_FromAddressID     INT DEFAULT NULL;
    DECLARE v_FromLatitude      DECIMAL(10,7);
    DECLARE v_DeliveryFee       DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_PendingStatusID   INT DEFAULT NULL;
    DECLARE v_ItemAlreadyLinked INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        -- Rollback FIRST so the log insert below runs outside the
        -- failed transaction and actually survives / commits.
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_AddOrderItemToDelivery',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'ProductID', p_ProductID,
                'OrderID', p_OrderID,
                'OrderItemID', p_OrderItemID,
                'AddressToID', p_AddressToID
            )
        );

        SET v_Success    = FALSE;
        SET v_Message    = 'Une erreur est survenue lors du traitement de l''article.';
        SET v_DeliveryID = NULL;
    END;

    SET v_Success    = FALSE;
    SET v_Message    = '';
    SET v_DeliveryID = NULL;

    -- ------------------------------------------------
    -- Resolve product price + vendor's UserID
    -- ------------------------------------------------
    SELECT BasePrice, VendorID
    INTO v_BasePrice, v_UserID
    FROM Products
    WHERE ProductID = p_ProductID
    LIMIT 1;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Produit introuvable.';
        LEAVE main_block;
    END IF;

    -- ------------------------------------------------
    -- Resolve VendorProfileID
    -- ------------------------------------------------
    SELECT VendorProfileID
    INTO v_VendorProfileID
    FROM VendorProfiles
    WHERE UserID = v_UserID
    LIMIT 1;

    IF v_VendorProfileID IS NULL THEN
        SET v_Message = 'Profil vendeur introuvable pour ce produit.';
        LEAVE main_block;
    END IF;

    -- ------------------------------------------------
    -- Resolve vendor's pickup / default shipping address
    -- ------------------------------------------------
    SELECT AddressID, Latitude
    INTO v_FromAddressID, v_FromLatitude
    FROM Addresses
    WHERE UserID = v_UserID
      AND IsDefaultShipping = 1
    LIMIT 1;

    IF v_FromAddressID IS NULL THEN
        SET v_Message = 'Adresse de collecte introuvable pour ce vendeur.';
        LEAVE main_block;
    END IF;

    -- ------------------------------------------------
    -- Check this order item isn't already linked to a delivery
    -- ------------------------------------------------
    SELECT COUNT(*) INTO v_ItemAlreadyLinked
    FROM DeliveryItems
    WHERE OrderItemID = p_OrderItemID;

    IF v_ItemAlreadyLinked > 0 THEN
        SET v_Message = 'Cet article est déjà rattaché à une livraison.';
        LEAVE main_block;
    END IF;

    START TRANSACTION;

    -- ------------------------------------------------
    -- Check whether a delivery already exists for
    -- (this order, this vendor) — group items by vendor
    -- ------------------------------------------------
    SELECT DeliveryID INTO v_DeliveryID
    FROM Deliveries
    WHERE OrderID = p_OrderID
      AND VendorProfileID = v_VendorProfileID
    LIMIT 1;

    IF v_DeliveryID IS NULL THEN
        -- Resolve pending status + shipping fee only when creating new
        SELECT DeliveryStatusID INTO v_PendingStatusID
        FROM DeliveryStatuses
        WHERE Code = 'pending'
        LIMIT 1;

        IF v_PendingStatusID IS NULL THEN
            SET v_Message = 'Statut de livraison "pending" introuvable.';
            ROLLBACK;
            LEAVE main_block;
        END IF;

        SET v_DeliveryFee = CalculateShippingFee(v_FromAddressID, p_AddressToID);

        INSERT INTO Deliveries (
            OrderID, VendorProfileID, DeliveryProfileID,
            AddressFromID, AddressToID,
            DeliveryStatusID, DeliveryFee, Notes,
            RequestedAt, CreatedAt, UpdatedAt
        )
        VALUES (
            p_OrderID, v_VendorProfileID, NULL,
            v_FromAddressID, p_AddressToID,
            v_PendingStatusID, v_DeliveryFee, p_Notes,
            NOW(), NOW(), NOW()
        );

        SET v_DeliveryID = LAST_INSERT_ID();

        INSERT INTO DeliveryStatusHistory (
            DeliveryID, DeliveryStatusID, Latitude, Longitude, ChangedAt
        )
        VALUES (
            v_DeliveryID, v_PendingStatusID, v_FromLatitude, NULL, NOW()
        );
    END IF;

    -- ------------------------------------------------
    -- Link the order item to the (new or existing) delivery
    -- ------------------------------------------------
    INSERT INTO DeliveryItems (DeliveryID, OrderItemID)
    VALUES (v_DeliveryID, p_OrderItemID);

    COMMIT;

    SET v_Success = TRUE;
    SET v_Message = 'Article rattaché à la livraison avec succès.';
END main_block $$

DELIMITER ;