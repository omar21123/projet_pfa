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

DROP PROCEDURE IF EXISTS SP_RegisterDeliveryAccount;

DELIMITER $$

CREATE PROCEDURE SP_RegisterDeliveryAccount (
    IN  p_FirstName         NVARCHAR(100),
    IN  p_LastName          NVARCHAR(100),
    IN  p_Email              NVARCHAR(255),
    IN  p_PhoneNumber        NVARCHAR(30),
    IN  p_PasswordHash       NVARCHAR(255),
    IN  p_VehicleType        NVARCHAR(50),
    IN  p_LicensePlate       NVARCHAR(20),
    IN  p_AssignedBy         INT,           -- who's creating this account (admin), NULL if self-registered
    IN  p_RefreshTokenHash   VARCHAR(255),
    IN  p_IPAddress          VARCHAR(45),
    IN  p_RefreshTTLDays     INT,
    OUT v_Success            BOOLEAN,
    OUT v_Message            VARCHAR(255),
    OUT v_UserID             INT,
    OUT v_PublicID           VARCHAR(64),
    OUT v_DeliveryProfileID  INT
)
main_block: BEGIN
    DECLARE v_EmailExists       INT DEFAULT 0;
    DECLARE v_PhoneExists       INT DEFAULT 0;
    DECLARE v_LivreurRoleID     INT DEFAULT NULL;

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
            'SP_RegisterDeliveryAccount',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'Email', p_Email,
                'PhoneNumber', p_PhoneNumber,
                'AssignedBy', p_AssignedBy
            )
        );

        SET v_Success           = FALSE;
        SET v_Message           = 'Une erreur est survenue lors de la création du compte livreur.';
        SET v_UserID             = NULL;
        SET v_PublicID           = NULL;
        SET v_DeliveryProfileID  = NULL;
    END;

    SET v_Success           = FALSE;
    SET v_Message           = '';
    SET v_UserID             = NULL;
    SET v_PublicID           = NULL;
    SET v_DeliveryProfileID  = NULL;

    -- ------------------------------------------------
    -- Basic validation
    -- ------------------------------------------------
    IF p_Email IS NULL OR TRIM(p_Email) = '' THEN
        SET v_Message = 'L''adresse email est obligatoire.';
        LEAVE main_block;
    END IF;

    IF p_PasswordHash IS NULL OR TRIM(p_PasswordHash) = '' THEN
        SET v_Message = 'Le mot de passe est obligatoire.';
        LEAVE main_block;
    END IF;

    -- ------------------------------------------------
    -- Uniqueness checks
    -- ------------------------------------------------
    SELECT COUNT(*) INTO v_EmailExists
    FROM Users
    WHERE Email = p_Email AND IsDeleted = 0;

    IF v_EmailExists > 0 THEN
        SET v_Message = 'Un compte existe déjà avec cet email.';
        LEAVE main_block;
    END IF;

    IF p_PhoneNumber IS NOT NULL AND TRIM(p_PhoneNumber) <> '' THEN
        SELECT COUNT(*) INTO v_PhoneExists
        FROM Users
        WHERE PhoneNumber = p_PhoneNumber AND IsDeleted = 0;

        IF v_PhoneExists > 0 THEN
            SET v_Message = 'Un compte existe déjà avec ce numéro de téléphone.';
            LEAVE main_block;
        END IF;
    END IF;

    -- ------------------------------------------------
    -- Resolve 'Livreur' role
    -- ------------------------------------------------
    SELECT RoleID INTO v_LivreurRoleID
    FROM Roles
    WHERE Code = 'LIVREUR'
    LIMIT 1;

    IF v_LivreurRoleID IS NULL THEN
        SET v_Message = 'Rôle "Livreur" introuvable. Veuillez le créer avant de continuer.';
        LEAVE main_block;
    END IF;

    START TRANSACTION;

    -- ------------------------------------------------
    -- 1) Create Users row
    -- ------------------------------------------------
    SET v_PublicID = UUID();

    INSERT INTO Users (
        PublicID, FirstName, LastName, DisplayName,
        Email, PhoneNumber, PasswordHash,
        HasPassword, EmailVerified, PhoneVerified,
        IsActive, IsDeleted,
        CreatedAt, UpdatedAt
    )
    VALUES (
        v_PublicID, p_FirstName, p_LastName,
        CONCAT(p_FirstName, ' ', p_LastName),
        p_Email, p_PhoneNumber, p_PasswordHash,
        1, 0, 0,
        1, 0,
        NOW(), NOW()
    );

    SET v_UserID = LAST_INSERT_ID();

    -- ------------------------------------------------
    -- 2) Assign 'Livreur' role
    -- ------------------------------------------------
    INSERT INTO UserRoles (UserID, RoleID, AssignedAt, AssignedBy)
    VALUES (v_UserID, v_LivreurRoleID, NOW(), p_AssignedBy);

    -- ------------------------------------------------
    -- 3) Create DeliveryProfiles row
    -- ------------------------------------------------
    INSERT INTO DeliveryProfiles (
        UserID, VehicleType, LicensePlate,
        Rating, DeliveryCount,
        TotalEarnings, WithdrawableBalance, PendingBalance,
        IsAvailable, LastOnlineAt,
        CurrentLatitude, CurrentLongitude,
        IdentityVerified, IsApproved, IsSuspended,
        CreatedAt, UpdatedAt
    )
    VALUES (
        v_UserID, p_VehicleType, p_LicensePlate,
        0.00, 0,
        0.00, 0.00, 0.00,
        0, NULL,
        NULL, NULL,
        0, 0, 0,
        NOW(), NOW()
    );

    SET v_DeliveryProfileID = LAST_INSERT_ID();

    -- ------------------------------------------------
    -- 4) Issue the initial refresh token (same pattern used for
    --    customer/vendor registration).
    -- ------------------------------------------------
    IF p_RefreshTokenHash IS NOT NULL THEN
        INSERT INTO RefreshTokens (
            UserID, TokenHash, IPAddress, ExpiresAt, CreatedAt
        )
        VALUES (
            v_UserID, p_RefreshTokenHash, p_IPAddress,
            DATE_ADD(NOW(), INTERVAL p_RefreshTTLDays DAY), NOW()
        );
    END IF;

    COMMIT;

    SET v_Success = TRUE;
    SET v_Message = 'Compte livreur créé avec succès. En attente de validation.';
END main_block $$

DELIMITER ;