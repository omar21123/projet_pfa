DELIMITER $$

CREATE FUNCTION CalculateShippingFee(
    p_FromAddressID INT,
    p_ToAddressID   INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    -- ─────────────────────────────────────────
    --  Source address fields
    -- ─────────────────────────────────────────
    DECLARE v_From_Country   VARCHAR(100);
    DECLARE v_From_Region    VARCHAR(100);
    DECLARE v_From_City      VARCHAR(100);

    -- ─────────────────────────────────────────
    --  Destination address fields
    -- ─────────────────────────────────────────
    DECLARE v_To_Country     VARCHAR(100);
    DECLARE v_To_Region      VARCHAR(100);
    DECLARE v_To_City        VARCHAR(100);

    -- ─────────────────────────────────────────
    --  Result
    -- ─────────────────────────────────────────
    DECLARE v_ShippingFee    DECIMAL(10,2) DEFAULT 0.00;

    -- ─────────────────────────────────────────
    --  Fetch FROM address
    -- ─────────────────────────────────────────
    SELECT Country, Region, City
    INTO   v_From_Country, v_From_Region, v_From_City
    FROM   Addresses
    WHERE  AddressID = p_FromAddressID
    LIMIT  1;

    -- ─────────────────────────────────────────
    --  Fetch TO address
    -- ─────────────────────────────────────────
    SELECT Country, Region, City
    INTO   v_To_Country, v_To_Region, v_To_City
    FROM   Addresses
    WHERE  AddressID = p_ToAddressID
    LIMIT  1;

    -- ─────────────────────────────────────────
    --  Guard: if either address not found → NULL
    -- ─────────────────────────────────────────
    IF v_From_Country IS NULL OR v_To_Country IS NULL THEN
        RETURN NULL;
    END IF;

    -- ─────────────────────────────────────────
    --  Fee logic  (customize amounts as needed)
    --
    --  Priority (most specific → least specific):
    --    1. Different Country  → highest fee
    --    2. Same Country  / Different Region → medium fee
    --    3. Same Country  / Same Region / Different City → low fee
    --    4. Same Country  / Same Region / Same City → lowest fee
    -- ─────────────────────────────────────────

    IF v_From_Country != v_To_Country THEN

        -- ── International ──────────────────────
        SET v_ShippingFee = 49.99;

    ELSEIF v_From_Region != v_To_Region
        OR  (v_From_Region IS NULL AND v_To_Region IS NOT NULL)
        OR  (v_From_Region IS NOT NULL AND v_To_Region IS NULL) THEN

        -- ── Domestic / different region ────────
        SET v_ShippingFee = 19.99;

    ELSEIF LOWER(TRIM(v_From_City)) != LOWER(TRIM(v_To_City)) THEN

        -- ── Same region / different city ───────
        SET v_ShippingFee = 9.99;

    ELSE

        -- ── Same city ──────────────────────────
        SET v_ShippingFee = 2.99;

    END IF;

    RETURN v_ShippingFee;

END$$

DELIMITER ;


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
BEGIN
    DECLARE v_BasePrice        DECIMAL(10,2);
    DECLARE v_UserID           INT DEFAULT NULL;
    DECLARE v_VendorProfileID  INT DEFAULT NULL;
    DECLARE v_FromAddressID    INT DEFAULT NULL;
    DECLARE v_FromLatitude     DECIMAL(10,7);
    DECLARE v_DeliveryFee      DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_PendingStatusID  INT DEFAULT NULL;
    DECLARE v_ItemAlreadyLinked INT DEFAULT 0;
    DECLARE v_ErrorMessage     VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_AddOrderItemToDelivery', v_ErrorMessage, NOW());

        SET v_Success    = FALSE;
        SET v_Message    = 'Une erreur est survenue lors du traitement de l''article.';
        SET v_DeliveryID = NULL;
    END;

    START TRANSACTION;

    -- ------------------------------------------------
    -- Resolve product price + vendor's UserID
    -- ------------------------------------------------
    SELECT BasePrice, VendorID
    INTO v_BasePrice, v_UserID
    FROM Products
    WHERE ProductID = p_ProductID
    LIMIT 1;

    IF v_UserID IS NULL THEN
        SET v_Success = FALSE;
        SET v_Message = 'Produit introuvable.';
        SET v_DeliveryID = NULL;
        ROLLBACK;
    ELSE
        -- ------------------------------------------------
        -- Resolve VendorProfileID
        -- ------------------------------------------------
        SELECT VendorProfileID
        INTO v_VendorProfileID
        FROM VendorProfiles
        WHERE UserID = v_UserID
        LIMIT 1;

        IF v_VendorProfileID IS NULL THEN
            SET v_Success = FALSE;
            SET v_Message = 'Profil vendeur introuvable pour ce produit.';
            SET v_DeliveryID = NULL;
            ROLLBACK;
        ELSE
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
                SET v_Success = FALSE;
                SET v_Message = 'Adresse de collecte introuvable pour ce vendeur.';
                SET v_DeliveryID = NULL;
                ROLLBACK;
            ELSE
                -- ------------------------------------------------
                -- Check this order item isn't already linked to a delivery
                -- ------------------------------------------------
                SELECT COUNT(*) INTO v_ItemAlreadyLinked
                FROM DeliveryItems
                WHERE OrderItemID = p_OrderItemID;

                IF v_ItemAlreadyLinked > 0 THEN
                    SET v_Success = FALSE;
                    SET v_Message = 'Cet article est déjà rattaché à une livraison.';
                    SET v_DeliveryID = NULL;
                    ROLLBACK;
                ELSE
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

                    SET v_Success = TRUE;
                    SET v_Message = 'Article rattaché à la livraison avec succès.';

                    COMMIT;
                END IF;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;