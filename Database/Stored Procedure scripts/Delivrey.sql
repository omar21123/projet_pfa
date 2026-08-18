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
    IN  p_TokenHash          VARCHAR(255),
    IN  p_IPAddress          VARCHAR(45),
    IN  p_TTL                INT,
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
        IsAvailable, LastOnlineAt,
        CurrentLatitude, CurrentLongitude,
        IdentityVerified, IsApproved, IsSuspended,
        CreatedAt, UpdatedAt
    )
    VALUES (
        v_UserID, p_VehicleType, p_LicensePlate,
        0.00, 0,
        0, NULL,
        NULL, NULL,
        0, 0, 0,
        NOW(), NOW()
    );

    SET v_DeliveryProfileID = LAST_INSERT_ID();

    -- ------------------------------------------------
    -- 4) Issue the initial refresh token
    -- ------------------------------------------------
    INSERT INTO UserRefreshTokens
    (
        UserID,
        UserDeviceID,
        TokenHash,
        IPAddress,
        ExpiresAt,
        IsRevoked,
        RevokedAt,
        ReplacedByTokenHash
    )
    VALUES
    (
        v_UserID,
        NULL,
        p_TokenHash,
        p_IPAddress,
        DATE_ADD(UTC_TIMESTAMP(), INTERVAL p_TTL DAY),
        0,
        NULL,
        NULL
    );

    COMMIT;

    SET v_Success = TRUE;
    SET v_Message = 'Compte livreur créé avec succès. En attente de validation.';
END main_block $$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE SP_GetAllDeliveryProfiles (
    IN  p_Search        NVARCHAR(255),
    IN  p_IsAvailable   TINYINT,   -- NULL = no filter
    IN  p_IsApproved    TINYINT,   -- NULL = no filter
    IN  p_IsSuspended   TINYINT,   -- NULL = no filter
    IN  p_Page          INT,
    IN  p_PerPage        INT,
    OUT v_Success        BOOLEAN,
    OUT v_Message         VARCHAR(255),
    OUT v_TotalCount       INT
)
BEGIN
    DECLARE v_Offset       INT DEFAULT 0;
    DECLARE v_ErrorMessage VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_GetAllDeliveryProfiles', v_ErrorMessage, NOW());

        SET v_Success    = FALSE;
        SET v_Message    = 'Une erreur est survenue lors de la récupération des livreurs.';
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
    -- Total count (for pagination meta)
    -- ------------------------------------------------
    SELECT COUNT(*) INTO v_TotalCount
    FROM DeliveryProfiles dp
    INNER JOIN Users u ON u.UserID = dp.UserID
    WHERE (p_Search IS NULL OR p_Search = ''
           OR u.DisplayName LIKE CONCAT('%', p_Search, '%')
           OR u.Email LIKE CONCAT('%', p_Search, '%')
           OR dp.LicensePlate LIKE CONCAT('%', p_Search, '%'))
      AND (p_IsAvailable IS NULL OR dp.IsAvailable = p_IsAvailable)
      AND (p_IsApproved  IS NULL OR dp.IsApproved  = p_IsApproved)
      AND (p_IsSuspended IS NULL OR dp.IsSuspended = p_IsSuspended);

    -- ------------------------------------------------
    -- Page of results
    -- ------------------------------------------------
    SELECT
        dp.DeliveryProfileID,
        u.AvatarURL,
        u.DisplayName,
        u.Email,
        dp.VehicleType,
        dp.LicensePlate,
        dp.Rating,
        dp.DeliveryCount,
        dp.IdentityVerified,
        u.LastLoginAt,
        dp.IsAvailable,
        dp.IsApproved
    FROM DeliveryProfiles dp
    INNER JOIN Users u ON u.UserID = dp.UserID
    WHERE (p_Search IS NULL OR p_Search = ''
           OR u.DisplayName LIKE CONCAT('%', p_Search, '%')
           OR u.Email LIKE CONCAT('%', p_Search, '%')
           OR dp.LicensePlate LIKE CONCAT('%', p_Search, '%'))
      AND (p_IsAvailable IS NULL OR dp.IsAvailable = p_IsAvailable)
      AND (p_IsApproved  IS NULL OR dp.IsApproved  = p_IsApproved)
      AND (p_IsSuspended IS NULL OR dp.IsSuspended = p_IsSuspended)
    ORDER BY dp.CreatedAt DESC
    LIMIT p_PerPage OFFSET v_Offset;

    SET v_Success = TRUE;
    SET v_Message = 'Livreurs récupérés avec succès.';
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_GetDeliveryProfileById (
    IN  p_DeliveryProfileID   INT,
    OUT v_Success              BOOLEAN,
    OUT v_Message               VARCHAR(255)
)
BEGIN
    DECLARE v_ProfileExists   INT DEFAULT 0;
    DECLARE v_ErrorMessage    VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_GetDeliveryProfileById', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération du livreur.';
    END;

    SELECT COUNT(*) INTO v_ProfileExists
    FROM DeliveryProfiles
    WHERE DeliveryProfileID = p_DeliveryProfileID;

    IF v_ProfileExists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Profil livreur introuvable.';
    ELSE
        SELECT
            dp.DeliveryProfileID,
            dp.UserID,
            u.PublicID,
            u.FirstName,
            u.LastName,
            u.DisplayName,
            u.Email,
            u.PhoneNumber,
            u.AvatarURL,
            u.EmailVerified,
            u.PhoneVerified,
            u.IsActive             AS UserIsActive,
            u.LastLoginAt,
            u.CreatedAt             AS UserCreatedAt,

            dp.VehicleType,
            dp.LicensePlate,
            dp.Rating,
            dp.DeliveryCount,
            dp.IsAvailable,
            dp.LastOnlineAt,
            dp.CurrentLatitude,
            dp.CurrentLongitude,
            dp.IdentityVerified,
            dp.IsApproved,
            dp.IsSuspended,
            dp.CreatedAt             AS ProfileCreatedAt,
            dp.UpdatedAt             AS ProfileUpdatedAt,

            dw.DeliveryWalletID,
            dw.CurrentBalance,
            dw.WithdrawableBalance,
            dw.PendingBalance,
            dw.CurrencyCode,
            dw.IsLocked              AS WalletIsLocked

        FROM DeliveryProfiles dp
        INNER JOIN Users u          ON u.UserID = dp.UserID
        LEFT JOIN DeliveryWallets dw ON dw.DeliveryProfileID = dp.DeliveryProfileID
        WHERE dp.DeliveryProfileID = p_DeliveryProfileID
        LIMIT 1;

        SET v_Success = TRUE;
        SET v_Message = 'Livreur récupéré avec succès.';
    END IF;
END$$

DELIMITER ;
DROP PROCEDURE IF EXISTS SP_ApproveDeliveryProfile;

DELIMITER $$

CREATE PROCEDURE SP_ApproveDeliveryProfile (
    IN  p_DeliveryProfileID   INT,
    IN  p_ApprovedBy           INT,
    OUT v_Success              BOOLEAN,
    OUT v_Message               VARCHAR(255),
    OUT v_DeliveryWalletID      INT
)
BEGIN
    DECLARE v_ProfileExists    INT DEFAULT 0;
    DECLARE v_AlreadyApproved  TINYINT DEFAULT 0;
    DECLARE v_ErrorMessage     VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_ApproveDeliveryProfile', v_ErrorMessage, NOW());

        SET v_Success          = FALSE;
        SET v_Message          = 'Une erreur est survenue lors de l''approbation du livreur.';
        SET v_DeliveryWalletID = NULL;
    END;

    START TRANSACTION;

    SELECT COUNT(*), MAX(IsApproved)
    INTO v_ProfileExists, v_AlreadyApproved
    FROM DeliveryProfiles
    WHERE DeliveryProfileID = p_DeliveryProfileID
    FOR UPDATE;

    IF v_ProfileExists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Profil livreur introuvable.';
        SET v_DeliveryWalletID = NULL;
        ROLLBACK;
    ELSEIF v_AlreadyApproved = 1 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Ce livreur est déjà approuvé.';
        SET v_DeliveryWalletID = NULL;
        ROLLBACK;
    ELSE
        UPDATE DeliveryProfiles
        SET IsApproved       = 1,
            IdentityVerified = 1,
            IsSuspended       = 0,
            UpdatedAt          = NOW()
        WHERE DeliveryProfileID = p_DeliveryProfileID;

        -- Wallet may already exist (created at registration) — only
        -- create one if it's missing, don't duplicate it.
        SELECT DeliveryWalletID INTO v_DeliveryWalletID
        FROM DeliveryWallets
        WHERE DeliveryProfileID = p_DeliveryProfileID
        LIMIT 1;

        IF v_DeliveryWalletID IS NULL THEN
            INSERT INTO DeliveryWallets (
                DeliveryProfileID,
                CurrentBalance, WithdrawableBalance, PendingBalance,
                CurrencyCode, IsLocked,
                CreatedAt, UpdatedAt
            )
            VALUES (
                p_DeliveryProfileID,
                0.00, 0.00, 0.00,
                'MAD', 0,
                NOW(), NOW()
            );

            SET v_DeliveryWalletID = LAST_INSERT_ID();
        END IF;

        SET v_Success = TRUE;
        SET v_Message = 'Livreur approuvé avec succès.';

        COMMIT;
    END IF;
END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE SP_SuspendDeliveryProfile (
    IN  p_DeliveryProfileID   INT,
    IN  p_SuspendedBy          INT,
    IN  p_Reason                 NVARCHAR(500),
    OUT v_Success                 BOOLEAN,
    OUT v_Message                  VARCHAR(255)
)
BEGIN
    DECLARE v_ProfileExists    INT DEFAULT 0;
    DECLARE v_ErrorMessage     VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_SuspendDeliveryProfile', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la suspension du livreur.';
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_ProfileExists
    FROM DeliveryProfiles
    WHERE DeliveryProfileID = p_DeliveryProfileID
    FOR UPDATE;

    IF v_ProfileExists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Profil livreur introuvable.';
        ROLLBACK;
    ELSE
        UPDATE DeliveryProfiles
        SET IsSuspended  = 1,
            IsAvailable  = 0,
            UpdatedAt    = NOW()
        WHERE DeliveryProfileID = p_DeliveryProfileID;

        SET v_Success = TRUE;
        SET v_Message = 'Livreur suspendu avec succès.';

        COMMIT;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_GetDeliverySummary (
    IN  p_DeliveryID   INT,
    OUT v_Success       BOOLEAN,
    OUT v_Message        VARCHAR(255)
)
BEGIN
    DECLARE v_Exists     INT DEFAULT 0;
    DECLARE v_ErrorMessage VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_GetDeliverySummary', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération de la livraison.';
    END;

    SELECT COUNT(*) INTO v_Exists FROM Deliveries WHERE DeliveryID = p_DeliveryID;

    IF v_Exists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Livraison introuvable.';
    ELSE
        SELECT
            d.DeliveryID,
            COUNT(di.DeliveryItemID) AS TotalItems,

            af.AddressID    AS FromAddressID,
            af.AddressLine1 AS FromAddressLine1,
            af.AddressLine2 AS FromAddressLine2,
            af.City         AS FromCity,
            af.Region       AS FromRegion,
            af.PostalCode   AS FromPostalCode,
            af.Country      AS FromCountry,

            at.AddressID    AS ToAddressID,
            at.AddressLine1 AS ToAddressLine1,
            at.AddressLine2 AS ToAddressLine2,
            at.City         AS ToCity,
            at.Region       AS ToRegion,
            at.PostalCode   AS ToPostalCode,
            at.Country      AS ToCountry

        FROM Deliveries d
        INNER JOIN DeliveryItems di ON di.DeliveryID = d.DeliveryID
        INNER JOIN Addresses af     ON af.AddressID = d.AddressFromID
        INNER JOIN Addresses at     ON at.AddressID = d.AddressToID
        WHERE d.DeliveryID = p_DeliveryID
        GROUP BY d.DeliveryID;

        SET v_Success = TRUE;
        SET v_Message = 'Livraison récupérée avec succès.';
    END IF;
END$$

DELIMITER ;


DROP PROCEDURE IF EXISTS SP_AcceptDeliveryByID;

DELIMITER $$

CREATE PROCEDURE SP_AcceptDeliveryByID (
    IN  p_DeliveryID          INT,
    IN  p_DeliveryProfileID   INT,
    OUT v_Success              BOOLEAN,
    OUT v_Message               VARCHAR(255)
)
BEGIN
    DECLARE v_CurrentProfileID   INT DEFAULT NULL;
    DECLARE v_CurrentStatusID    INT DEFAULT NULL;
    DECLARE v_PendingStatusID    INT DEFAULT NULL;
    DECLARE v_AcceptedStatusID   INT DEFAULT NULL;
    DECLARE v_DeliveryExists     INT DEFAULT 0;
    DECLARE v_ProfileApproved    TINYINT DEFAULT 0;
    DECLARE v_ProfileSuspended   TINYINT DEFAULT 0;
    DECLARE v_ErrorMessage       VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_AcceptDeliveryByID', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de l''acceptation de la livraison.';
    END;

    START TRANSACTION;

    -- ------------------------------------------------
    -- Validate the livreur first
    -- ------------------------------------------------
    SELECT IsApproved, IsSuspended
    INTO v_ProfileApproved, v_ProfileSuspended
    FROM DeliveryProfiles
    WHERE DeliveryProfileID = p_DeliveryProfileID;

    IF v_ProfileApproved IS NULL THEN
        SET v_Success = FALSE;
        SET v_Message = 'Profil livreur introuvable.';
        ROLLBACK;
    ELSEIF v_ProfileApproved = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Votre compte n''est pas encore approuvé.';
        ROLLBACK;
    ELSEIF v_ProfileSuspended = 1 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Votre compte est suspendu.';
        ROLLBACK;
    ELSE
        -- ------------------------------------------------
        -- Lock the delivery row to prevent two livreurs
        -- accepting the same delivery simultaneously
        -- ------------------------------------------------
        SELECT COUNT(*), MAX(DeliveryProfileID), MAX(DeliveryStatusID)
        INTO v_DeliveryExists, v_CurrentProfileID, v_CurrentStatusID
        FROM Deliveries
        WHERE DeliveryID = p_DeliveryID
        FOR UPDATE;

        IF v_DeliveryExists = 0 THEN
            SET v_Success = FALSE;
            SET v_Message = 'Livraison introuvable.';
            ROLLBACK;
        ELSEIF v_CurrentProfileID IS NOT NULL THEN
            SET v_Success = FALSE;
            SET v_Message = 'Cette livraison a déjà été acceptée par un autre livreur.';
            ROLLBACK;
        ELSE
            SELECT DeliveryStatusID INTO v_PendingStatusID
            FROM DeliveryStatuses WHERE Code = 'pending' LIMIT 1;

            IF v_CurrentStatusID <> v_PendingStatusID THEN
                SET v_Success = FALSE;
                SET v_Message = 'Cette livraison n''est plus disponible pour acceptation.';
                ROLLBACK;
            ELSE
                SELECT DeliveryStatusID INTO v_AcceptedStatusID
                FROM DeliveryStatuses WHERE Code = 'accepted' LIMIT 1;

                -- 1) Update Deliveries
                UPDATE Deliveries
                SET DeliveryProfileID = p_DeliveryProfileID,
                    DeliveryStatusID  = v_AcceptedStatusID,
                    AcceptedAt        = NOW(),
                    UpdatedAt         = NOW()
                WHERE DeliveryID = p_DeliveryID;

                -- 2) Log the status change
                INSERT INTO DeliveryStatusHistory (
                    DeliveryID, DeliveryStatusID, Latitude, Longitude, ChangedAt
                )
                VALUES (
                    p_DeliveryID, v_AcceptedStatusID, NULL, NULL, NOW()
                );

                -- 3) Bump the livreur's LastOnlineAt (they're actively engaging)
                UPDATE DeliveryProfiles
                SET LastOnlineAt = NOW()
                WHERE DeliveryProfileID = p_DeliveryProfileID;

                SET v_Success = TRUE;
                SET v_Message = 'Livraison acceptée avec succès.';

                COMMIT;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_GetVendorDeliveries (
    IN  p_VendorProfileID   INT,
    IN  p_StatusCode         VARCHAR(50),   -- NULL = all statuses
    IN  p_IsTaken             TINYINT,        -- NULL = both, 1 = has livreur, 0 = not yet taken
    IN  p_Page                 INT,
    IN  p_PerPage                INT,
    OUT v_Success                 BOOLEAN,
    OUT v_Message                  VARCHAR(255),
    OUT v_TotalCount                INT
)
BEGIN
    DECLARE v_VendorExists   INT DEFAULT 0;
    DECLARE v_Offset          INT DEFAULT 0;
    DECLARE v_ErrorMessage    VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_GetVendorDeliveries', v_ErrorMessage, NOW());

        SET v_Success    = FALSE;
        SET v_Message    = 'Une erreur est survenue lors de la récupération des livraisons.';
        SET v_TotalCount = 0;
    END;

    SELECT COUNT(*) INTO v_VendorExists
    FROM VendorProfiles
    WHERE VendorProfileID = p_VendorProfileID;

    IF v_VendorExists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Profil vendeur introuvable.';
        SET v_TotalCount = 0;
    ELSE
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
        FROM Deliveries d
        INNER JOIN DeliveryStatuses ds ON ds.DeliveryStatusID = d.DeliveryStatusID
        WHERE d.VendorProfileID = p_VendorProfileID
          AND (p_StatusCode IS NULL OR p_StatusCode = '' OR ds.Code = p_StatusCode)
          AND (
              p_IsTaken IS NULL
              OR (p_IsTaken = 1 AND d.DeliveryProfileID IS NOT NULL)
              OR (p_IsTaken = 0 AND d.DeliveryProfileID IS NULL)
          );

        -- ------------------------------------------------
        -- Page of results, newest first
        -- ------------------------------------------------
        SELECT
            d.DeliveryID,
            d.OrderID,

            ds.Code AS StatusCode,
            ds.Name AS StatusName,

            (d.DeliveryProfileID IS NOT NULL) AS IsTaken,
            d.DeliveryProfileID,
            u.DisplayName  AS LivreurName,
            u.PhoneNumber  AS LivreurPhone,

            d.DeliveryFee,
            (SELECT COUNT(*) FROM DeliveryItems di WHERE di.DeliveryID = d.DeliveryID) AS TotalItems,

            at.City    AS ToCity,
            at.Region  AS ToRegion,

            d.RequestedAt,
            d.AcceptedAt,
            d.DeliveredAt

        FROM Deliveries d
        INNER JOIN DeliveryStatuses ds  ON ds.DeliveryStatusID = d.DeliveryStatusID
        INNER JOIN Addresses at         ON at.AddressID = d.AddressToID
        LEFT JOIN DeliveryProfiles dp   ON dp.DeliveryProfileID = d.DeliveryProfileID
        LEFT JOIN Users u               ON u.UserID = dp.UserID
        WHERE d.VendorProfileID = p_VendorProfileID
          AND (p_StatusCode IS NULL OR p_StatusCode = '' OR ds.Code = p_StatusCode)
          AND (
              p_IsTaken IS NULL
              OR (p_IsTaken = 1 AND d.DeliveryProfileID IS NOT NULL)
              OR (p_IsTaken = 0 AND d.DeliveryProfileID IS NULL)
          )
        ORDER BY d.RequestedAt DESC
        LIMIT p_PerPage OFFSET v_Offset;

        SET v_Success = TRUE;
        SET v_Message = 'Livraisons récupérées avec succès.';
    END IF;
END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE SP_GetDeliveryDetails (
    IN  p_DeliveryID   INT,
    OUT v_Success        BOOLEAN,
    OUT v_Message         VARCHAR(255)
)
BEGIN
    DECLARE v_Exists       INT DEFAULT 0;
    DECLARE v_ErrorMessage VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_GetDeliveryDetails', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération de la livraison.';
    END;

    SELECT COUNT(*) INTO v_Exists FROM Deliveries WHERE DeliveryID = p_DeliveryID;

    IF v_Exists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Livraison introuvable.';
    ELSE
        SELECT
            d.DeliveryID,
            d.OrderID,
            d.VendorProfileID,
            vp.StoreName,

            ds.Code AS StatusCode,
            ds.Name AS StatusName,

            d.DeliveryFee,
            d.Notes,
            (SELECT COUNT(*) FROM DeliveryItems di WHERE di.DeliveryID = d.DeliveryID) AS TotalItems,

            -- Pickup address
            af.AddressID    AS FromAddressID,
            af.AddressLine1 AS FromAddressLine1,
            af.AddressLine2 AS FromAddressLine2,
            af.City         AS FromCity,
            af.Region       AS FromRegion,
            af.PostalCode   AS FromPostalCode,
            af.Country      AS FromCountry,
            af.Latitude     AS FromLatitude,
            af.Longitude    AS FromLongitude,

            -- Dropoff address
            at.AddressID    AS ToAddressID,
            at.AddressLine1 AS ToAddressLine1,
            at.AddressLine2 AS ToAddressLine2,
            at.City         AS ToCity,
            at.Region       AS ToRegion,
            at.PostalCode   AS ToPostalCode,
            at.Country      AS ToCountry,
            at.Latitude     AS ToLatitude,
            at.Longitude    AS ToLongitude,

            -- Assigned livreur (NULL if not accepted yet)
            dp.DeliveryProfileID,
            u.DisplayName    AS LivreurName,
            u.PhoneNumber    AS LivreurPhone,
            u.AvatarURL       AS LivreurAvatarURL,
            dp.VehicleType,
            dp.LicensePlate,
            dp.Rating         AS LivreurRating,
            dp.CurrentLatitude,
            dp.CurrentLongitude,

            d.RequestedAt,
            d.AcceptedAt,
            d.PickedUpAt,
            d.DeliveredAt,
            d.CancelledAt

        FROM Deliveries d
        INNER JOIN DeliveryStatuses ds  ON ds.DeliveryStatusID = d.DeliveryStatusID
        INNER JOIN VendorProfiles vp    ON vp.VendorProfileID = d.VendorProfileID
        INNER JOIN Addresses af         ON af.AddressID = d.AddressFromID
        INNER JOIN Addresses at         ON at.AddressID = d.AddressToID
        LEFT JOIN DeliveryProfiles dp   ON dp.DeliveryProfileID = d.DeliveryProfileID
        LEFT JOIN Users u               ON u.UserID = dp.UserID
        WHERE d.DeliveryID = p_DeliveryID
        LIMIT 1;

        SET v_Success = TRUE;
        SET v_Message = 'Livraison récupérée avec succès.';
    END IF;
END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE SP_MarkDeliveryPickedUp (
    IN  p_DeliveryID          INT,
    IN  p_DeliveryProfileID   INT,
    OUT v_Success              BOOLEAN,
    OUT v_Message               VARCHAR(255)
)
BEGIN
    DECLARE v_DeliveryExists    INT DEFAULT 0;
    DECLARE v_AssignedProfileID INT DEFAULT NULL;
    DECLARE v_CurrentStatusID   INT DEFAULT NULL;
    DECLARE v_AcceptedStatusID  INT DEFAULT NULL;
    DECLARE v_PickedUpStatusID  INT DEFAULT NULL;
    DECLARE v_ErrorMessage      VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_MarkDeliveryPickedUp', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la mise à jour de la livraison.';
    END;

    START TRANSACTION;

    -- Lock the row — avoid racing with a concurrent status change
    SELECT COUNT(*), MAX(DeliveryProfileID), MAX(DeliveryStatusID)
    INTO v_DeliveryExists, v_AssignedProfileID, v_CurrentStatusID
    FROM Deliveries
    WHERE DeliveryID = p_DeliveryID
    FOR UPDATE;

    IF v_DeliveryExists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Livraison introuvable.';
        ROLLBACK;
    ELSEIF v_AssignedProfileID IS NULL THEN
        SET v_Success = FALSE;
        SET v_Message = 'Cette livraison n''a pas encore été acceptée par un livreur.';
        ROLLBACK;
    ELSEIF v_AssignedProfileID <> p_DeliveryProfileID THEN
        SET v_Success = FALSE;
        SET v_Message = 'Cette livraison est assignée à un autre livreur.';
        ROLLBACK;
    ELSE
        SELECT DeliveryStatusID INTO v_AcceptedStatusID
        FROM DeliveryStatuses WHERE Code = 'accepted' LIMIT 1;

        SELECT DeliveryStatusID INTO v_PickedUpStatusID
        FROM DeliveryStatuses WHERE Code = 'picked_up' LIMIT 1;

        IF v_CurrentStatusID <> v_AcceptedStatusID THEN
            SET v_Success = FALSE;
            SET v_Message = 'Cette livraison doit être au statut "acceptée" avant d''être récupérée.';
            ROLLBACK;
        ELSE
            UPDATE Deliveries
            SET DeliveryStatusID = v_PickedUpStatusID,
                PickedUpAt       = NOW(),
                UpdatedAt        = NOW()
            WHERE DeliveryID = p_DeliveryID;

            INSERT INTO DeliveryStatusHistory (
                DeliveryID, DeliveryStatusID, Latitude, Longitude, ChangedAt
            )
            VALUES (
                p_DeliveryID, v_PickedUpStatusID, NULL, NULL, NOW()
            );

            SET v_Success = TRUE;
            SET v_Message = 'Livraison marquée comme récupérée avec succès.';

            COMMIT;
        END IF;
    END IF;
END$$

DELIMITER ;
DROP PROCEDURE IF EXISTS SP_MarkOrderAsShipped;

DELIMITER $$

CREATE PROCEDURE SP_MarkOrderAsShipped (
    IN  p_OrderID           INT,
    IN  p_VendorProfileID    INT,
    OUT v_Success             BOOLEAN,
    OUT v_Message              VARCHAR(255),
    OUT v_OrderFullyShipped     BOOLEAN
)
BEGIN
    DECLARE v_OrderExists         INT DEFAULT 0;
    DECLARE v_VendorHasItems      INT DEFAULT 0;
    DECLARE v_DeliveryID          INT DEFAULT NULL;
    DECLARE v_DeliveryStatusCode  VARCHAR(50) DEFAULT NULL;
    DECLARE v_CurrentOrderStatus  INT DEFAULT NULL;
    DECLARE v_ConfirmedStatusID   INT DEFAULT NULL;
    DECLARE v_ShippedStatusID     INT DEFAULT NULL;
    DECLARE v_OtherVendorsNotReady INT DEFAULT 0;
    DECLARE v_ErrorMessage        VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_MarkOrderAsShipped', v_ErrorMessage, NOW());

        SET v_Success            = FALSE;
        SET v_Message            = 'Une erreur est survenue lors de la mise à jour de la commande.';
        SET v_OrderFullyShipped  = FALSE;
    END;

    START TRANSACTION;

    -- ------------------------------------------------
    -- Order must exist
    -- ------------------------------------------------
    SELECT COUNT(*), MAX(OrderStatusID)
    INTO v_OrderExists, v_CurrentOrderStatus
    FROM Orders
    WHERE OrderID = p_OrderID
    FOR UPDATE;

    IF v_OrderExists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Commande introuvable.';
        SET v_OrderFullyShipped = FALSE;
        ROLLBACK;
    ELSE
        -- ------------------------------------------------
        -- This vendor must actually have items in this order
        -- ------------------------------------------------
        SELECT COUNT(*) INTO v_VendorHasItems
        FROM OrderItems
        WHERE OrderID = p_OrderID
          AND VendorProfileID = p_VendorProfileID;

        IF v_VendorHasItems = 0 THEN
            SET v_Success = FALSE;
            SET v_Message = 'Vous n''avez aucun article dans cette commande.';
            SET v_OrderFullyShipped = FALSE;
            ROLLBACK;
        ELSE
            -- ------------------------------------------------
            -- This vendor's delivery must exist and be picked_up (or beyond)
            -- ------------------------------------------------
            SELECT d.DeliveryID, ds.Code
            INTO v_DeliveryID, v_DeliveryStatusCode
            FROM Deliveries d
            INNER JOIN DeliveryStatuses ds ON ds.DeliveryStatusID = d.DeliveryStatusID
            WHERE d.OrderID = p_OrderID
              AND d.VendorProfileID = p_VendorProfileID
            LIMIT 1;

            IF v_DeliveryID IS NULL THEN
                SET v_Success = FALSE;
                SET v_Message = 'Aucune livraison n''a été créée pour vos articles de cette commande.';
                SET v_OrderFullyShipped = FALSE;
                ROLLBACK;
            ELSEIF v_DeliveryStatusCode NOT IN ('picked_up', 'in_transit', 'delivered') THEN
                SET v_Success = FALSE;
                SET v_Message = 'Votre livraison doit être récupérée par le livreur avant de marquer la commande comme expédiée.';
                SET v_OrderFullyShipped = FALSE;
                ROLLBACK;
            ELSE
                SELECT OrderStatusID INTO v_ConfirmedStatusID
                FROM OrderStatus WHERE Code = 'CONFIRMED' LIMIT 1;

                SELECT OrderStatusID INTO v_ShippedStatusID
                FROM OrderStatus WHERE Code = 'SHIPPED' LIMIT 1;

                -- Order-level status must be Confirmed before it can ship
                IF v_CurrentOrderStatus <> v_ConfirmedStatusID THEN
                    SET v_Success = FALSE;
                    SET v_Message = 'Cette commande n''est pas dans un état permettant l''expédition.';
                    SET v_OrderFullyShipped = FALSE;
                    ROLLBACK;
                ELSE
                    -- ------------------------------------------------
                    -- Check whether EVERY vendor on this order has
                    -- their delivery picked_up or beyond, before
                    -- flipping the order-level status
                    -- ------------------------------------------------
                    SELECT COUNT(*) INTO v_OtherVendorsNotReady
                    FROM Deliveries d
                    INNER JOIN DeliveryStatuses ds ON ds.DeliveryStatusID = d.DeliveryStatusID
                    WHERE d.OrderID = p_OrderID
                      AND ds.Code NOT IN ('picked_up', 'in_transit', 'delivered');

                    IF v_OtherVendorsNotReady = 0 THEN
                        UPDATE Orders
                        SET OrderStatusID = v_ShippedStatusID,
                            UpdatedAt     = NOW()
                        WHERE OrderID = p_OrderID;

                        SET v_OrderFullyShipped = TRUE;
                        SET v_Message = 'Commande marquée comme expédiée avec succès.';
                    ELSE
                        SET v_OrderFullyShipped = FALSE;
                        SET v_Message = 'Votre partie de la commande est prête. En attente des autres vendeurs avant expédition complète.';
                    END IF;

                    SET v_Success = TRUE;

                    COMMIT;
                END IF;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE SP_MarkDeliveryInTransit (
    IN  p_DeliveryID          INT,
    IN  p_DeliveryProfileID   INT,
    OUT v_Success              BOOLEAN,
    OUT v_Message               VARCHAR(255)
)
BEGIN
    DECLARE v_DeliveryExists    INT DEFAULT 0;
    DECLARE v_AssignedProfileID INT DEFAULT NULL;
    DECLARE v_CurrentStatusID   INT DEFAULT NULL;
    DECLARE v_PickedUpStatusID  INT DEFAULT NULL;
    DECLARE v_InTransitStatusID INT DEFAULT NULL;
    DECLARE v_ErrorMessage      VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_MarkDeliveryInTransit', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la mise à jour de la livraison.';
    END;

    START TRANSACTION;

    SELECT COUNT(*), MAX(DeliveryProfileID), MAX(DeliveryStatusID)
    INTO v_DeliveryExists, v_AssignedProfileID, v_CurrentStatusID
    FROM Deliveries
    WHERE DeliveryID = p_DeliveryID
    FOR UPDATE;

    IF v_DeliveryExists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Livraison introuvable.';
        ROLLBACK;
    ELSEIF v_AssignedProfileID IS NULL THEN
        SET v_Success = FALSE;
        SET v_Message = 'Cette livraison n''a pas encore été acceptée par un livreur.';
        ROLLBACK;
    ELSEIF v_AssignedProfileID <> p_DeliveryProfileID THEN
        SET v_Success = FALSE;
        SET v_Message = 'Cette livraison est assignée à un autre livreur.';
        ROLLBACK;
    ELSE
        SELECT DeliveryStatusID INTO v_PickedUpStatusID
        FROM DeliveryStatuses WHERE Code = 'picked_up' LIMIT 1;

        SELECT DeliveryStatusID INTO v_InTransitStatusID
        FROM DeliveryStatuses WHERE Code = 'in_transit' LIMIT 1;

        IF v_CurrentStatusID <> v_PickedUpStatusID THEN
            SET v_Success = FALSE;
            SET v_Message = 'Cette livraison doit être au statut "récupérée" avant de passer en transit.';
            ROLLBACK;
        ELSE
            UPDATE Deliveries
            SET DeliveryStatusID = v_InTransitStatusID,
                UpdatedAt        = NOW()
            WHERE DeliveryID = p_DeliveryID;

            INSERT INTO DeliveryStatusHistory (
                DeliveryID, DeliveryStatusID, Latitude, Longitude, ChangedAt
            )
            VALUES (
                p_DeliveryID, v_InTransitStatusID, NULL, NULL, NOW()
            );

            SET v_Success = TRUE;
            SET v_Message = 'Livraison marquée en transit avec succès.';

            COMMIT;
        END IF;
    END IF;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS SP_MarkCashCollected;

DELIMITER $$

CREATE PROCEDURE SP_MarkCashCollected (
    IN  p_DeliveryID          INT,
    IN  p_DeliveryProfileID   INT,
    IN  p_CollectedAmount      DECIMAL(10,2),
    OUT v_Success               BOOLEAN,
    OUT v_Message                VARCHAR(255)
)
BEGIN
    DECLARE v_DeliveryExists     INT DEFAULT 0;
    DECLARE v_AssignedProfileID  INT DEFAULT NULL;
    DECLARE v_RecordExists       INT DEFAULT 0;
    DECLARE v_AlreadyCollected   TINYINT DEFAULT 0;
    DECLARE v_AmountDue          DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_ErrorMessage       VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_MarkCashCollected', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de l''enregistrement de l''encaissement.';
    END;

    START TRANSACTION;

    -- ------------------------------------------------
    -- Delivery must exist and be assigned to this livreur
    -- ------------------------------------------------
    SELECT COUNT(*), MAX(DeliveryProfileID)
    INTO v_DeliveryExists, v_AssignedProfileID
    FROM Deliveries
    WHERE DeliveryID = p_DeliveryID
    FOR UPDATE;

    IF v_DeliveryExists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Livraison introuvable.';
        ROLLBACK;
    ELSEIF v_AssignedProfileID IS NULL OR v_AssignedProfileID <> p_DeliveryProfileID THEN
        SET v_Success = FALSE;
        SET v_Message = 'Cette livraison n''est pas assignée à votre compte.';
        ROLLBACK;
    ELSE
        -- ------------------------------------------------
        -- Does a cash-collection record already exist?
        -- ------------------------------------------------
        SELECT COUNT(*), MAX(IsCollected)
        INTO v_RecordExists, v_AlreadyCollected
        FROM DeliveryCashCollections
        WHERE DeliveryID = p_DeliveryID
        FOR UPDATE;

        IF v_RecordExists = 0 THEN
            -- ------------------------------------------------
            -- No record yet — create one first.
            -- AmountDue = sum of this delivery's order items' Total
            -- ------------------------------------------------
            SELECT COALESCE(SUM(oi.Total), 0.00)
            INTO v_AmountDue
            FROM DeliveryItems di
            INNER JOIN OrderItems oi ON oi.OrderItemID = di.OrderItemID
            WHERE di.DeliveryID = p_DeliveryID;

            INSERT INTO DeliveryCashCollections (
                DeliveryID, DeliveryProfileID,
                AmountDue, CurrencyCode,
                IsCollected, CollectedAmount, CollectedAt,
                IsRemitted,
                CreatedAt, UpdatedAt
            )
            VALUES (
                p_DeliveryID, p_DeliveryProfileID,
                v_AmountDue, 'MAD',
                1, p_CollectedAmount, NOW(),
                0,
                NOW(), NOW()
            );

            SET v_Success = TRUE;
            SET v_Message = 'Encaissement enregistré avec succès.';

            COMMIT;
        ELSEIF v_AlreadyCollected = 1 THEN
            SET v_Success = FALSE;
            SET v_Message = 'Ce montant a déjà été enregistré comme encaissé.';
            ROLLBACK;
        ELSE
            -- Record exists but not yet collected — update it
            UPDATE DeliveryCashCollections
            SET IsCollected      = 1,
                CollectedAmount  = p_CollectedAmount,
                CollectedAt      = NOW(),
                UpdatedAt        = NOW()
            WHERE DeliveryID = p_DeliveryID;

            SET v_Success = TRUE;
            SET v_Message = 'Encaissement enregistré avec succès.';

            COMMIT;
        END IF;
    END IF;
END$$

DROP PROCEDURE IF EXISTS SP_MarkDeliveryDeliveredByLivreur;

DELIMITER $$

CREATE PROCEDURE SP_MarkDeliveryDeliveredByLivreur (
    IN  p_DeliveryID          INT,
    IN  p_DeliveryProfileID   INT,
    IN  p_CollectedAmount     DECIMAL(10,2),
    OUT v_Success             BOOLEAN,
    OUT v_Message             VARCHAR(255)
)
BEGIN
    DECLARE v_DeliveryExists          INT DEFAULT 0;
    DECLARE v_AssignedProfileID       INT DEFAULT NULL;
    DECLARE v_CurrentStatusID         INT DEFAULT NULL;
    DECLARE v_InTransitStatusID       INT DEFAULT NULL;
    DECLARE v_DeliveredStatusID       INT DEFAULT NULL;
    DECLARE v_DeliveryFee             DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_VendorProfileID         INT DEFAULT NULL;
    DECLARE v_OrderID                 INT DEFAULT NULL;
    DECLARE v_PaymentMethodID         INT DEFAULT NULL;
    DECLARE v_PaymentID               INT DEFAULT NULL;

    DECLARE v_ItemsTotal              DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_PlatformCommission      DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_VendorPayout            DECIMAL(10,2) DEFAULT 0.00;

    DECLARE v_BankAccountID           INT DEFAULT NULL;
    DECLARE v_HoldReleaseAt           DATETIME DEFAULT NULL;

    DECLARE v_TotalDeliveries         INT DEFAULT 0;
    DECLARE v_DeliveredDeliveries     INT DEFAULT 0;
    DECLARE v_DeliveredOrderStatusID  INT DEFAULT NULL;

    DECLARE v_CashSuccess             BOOLEAN DEFAULT NULL;
    DECLARE v_CashMessage             VARCHAR(255) DEFAULT NULL;

    DECLARE v_ErrorMessage            VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_MarkDeliveryDeliveredByLivreur', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la finalisation de la livraison.';
    END;

    START TRANSACTION;

    -- 1) Verify delivery exists, lock it
    SELECT COUNT(*), MAX(DeliveryProfileID), MAX(DeliveryStatusID),
           MAX(DeliveryFee), MAX(VendorProfileID), MAX(OrderID)
    INTO v_DeliveryExists, v_AssignedProfileID, v_CurrentStatusID,
         v_DeliveryFee, v_VendorProfileID, v_OrderID
    FROM Deliveries
    WHERE DeliveryID = p_DeliveryID
    FOR UPDATE;

    IF v_DeliveryExists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Livraison introuvable.';
        ROLLBACK;

    ELSEIF v_AssignedProfileID IS NULL OR v_AssignedProfileID <> p_DeliveryProfileID THEN
        SET v_Success = FALSE;
        SET v_Message = 'Cette livraison n''est pas assignée à votre compte.';
        ROLLBACK;

    ELSE
        -- ------------------------------------------------
        -- Resolve the payment for this order up front — a hold
        -- row requires a PaymentID (NOT NULL FK), so fail fast
        -- here rather than after status/wallet changes are made.
        -- ------------------------------------------------
        SELECT PaymentID INTO v_PaymentID
        FROM Payments
        WHERE OrderID = v_OrderID
        ORDER BY PaymentID DESC
        LIMIT 1;

        -- Resolve vendor's BankAccountID up front too
        SELECT BankAccountID INTO v_BankAccountID
        FROM BankAccounts
        WHERE VendorProfileID = v_VendorProfileID
        LIMIT 1;

        IF v_PaymentID IS NULL THEN
            SET v_Success = FALSE;
            SET v_Message = 'Aucun paiement trouvé pour cette commande.';
            ROLLBACK;
        ELSEIF v_BankAccountID IS NULL THEN
            SET v_Success = FALSE;
            SET v_Message = 'Compte bancaire introuvable pour ce vendeur.';
            ROLLBACK;
        ELSE
            SELECT DeliveryStatusID INTO v_InTransitStatusID
            FROM DeliveryStatuses WHERE Code = 'in_transit' LIMIT 1;

            SELECT DeliveryStatusID INTO v_DeliveredStatusID
            FROM DeliveryStatuses WHERE Code = 'delivered' LIMIT 1;

            IF v_CurrentStatusID <> v_InTransitStatusID THEN
                SET v_Success = FALSE;
                SET v_Message = 'Cette livraison doit être en transit avant d''être marquée comme livrée.';
                ROLLBACK;
            ELSE
                -- 2) Mark delivery delivered
                UPDATE Deliveries
                SET DeliveryStatusID = v_DeliveredStatusID,
                    DeliveredAt      = NOW(),
                    UpdatedAt        = NOW()
                WHERE DeliveryID = p_DeliveryID;

                INSERT INTO DeliveryStatusHistory (
                    DeliveryID, DeliveryStatusID, Latitude, Longitude, ChangedAt
                )
                VALUES (p_DeliveryID, v_DeliveredStatusID, NULL, NULL, NOW());

                -- 3) Credit livreur wallet (unchanged — livreur's own
                -- fee is released immediately, no hold on this side)
                UPDATE DeliveryProfiles
                SET DeliveryCount = DeliveryCount + 1
                WHERE DeliveryProfileID = p_DeliveryProfileID;

                UPDATE DeliveryWallets
                SET CurrentBalance      = CurrentBalance + v_DeliveryFee,
                    WithdrawableBalance = WithdrawableBalance + v_DeliveryFee,
                    UpdatedAt           = NOW()
                WHERE DeliveryProfileID = p_DeliveryProfileID;

                -- ------------------------------------------------
                -- 4) Vendor payout (80%) — now goes through a HOLD,
                -- not a direct WithdrawableBalance credit.
                -- ------------------------------------------------
                SELECT COALESCE(SUM(oi.Total), 0.00)
                INTO v_ItemsTotal
                FROM DeliveryItems di
                INNER JOIN OrderItems oi ON oi.OrderItemID = di.OrderItemID
                WHERE di.DeliveryID = p_DeliveryID;

                SET v_PlatformCommission = ROUND(v_ItemsTotal * 0.20, 2);
                SET v_VendorPayout       = v_ItemsTotal - v_PlatformCommission;
                SET v_HoldReleaseAt      = NOW() + INTERVAL 3 DAY; -- hold period, adjust as needed

                UPDATE BankAccounts
                SET CurrentBalance = CurrentBalance + v_VendorPayout,  -- lifetime total, counted now
                    PendingBalance = PendingBalance + v_VendorPayout,  -- not withdrawable yet
                    UpdatedAt      = NOW()
                WHERE BankAccountID = v_BankAccountID;

                INSERT INTO BankAccountHolds (
                    BankAccountID, OrderID, PaymentID, Amount,
                    ReleaseAt, Status, CreatedAt
                )
                VALUES (
                    v_BankAccountID, v_OrderID, v_PaymentID, v_VendorPayout,
                    v_HoldReleaseAt, 0, NOW()
                );

                -- ------------------------------------------------
                -- 5) Check if ALL vendor deliveries for this order
                -- are now delivered
                -- ------------------------------------------------
                SELECT
                    COUNT(*),
                    SUM(CASE WHEN d.DeliveryStatusID = v_DeliveredStatusID THEN 1 ELSE 0 END)
                INTO v_TotalDeliveries, v_DeliveredDeliveries
                FROM Deliveries d
                WHERE d.OrderID = v_OrderID;

                IF v_TotalDeliveries > 0 AND v_TotalDeliveries = v_DeliveredDeliveries THEN
                    SELECT OrderStatusID INTO v_DeliveredOrderStatusID
                    FROM OrderStatuses
                    WHERE Code = 'delivered'
                    LIMIT 1;

                    UPDATE Orders
                    SET OrderStatusID = v_DeliveredOrderStatusID,
                        UpdatedAt     = NOW()
                    WHERE OrderID = v_OrderID;
                END IF;

                SET v_Success = TRUE;
                SET v_Message = 'Livraison finalisée avec succès.';

                COMMIT;

                -- COD handling after commit (has its own transaction)
                SELECT PaymentMethodID INTO v_PaymentMethodID
                FROM Orders
                WHERE OrderID = v_OrderID;

                IF v_PaymentMethodID = 1 THEN
                    CALL SP_MarkCashCollected(
                        p_DeliveryID,
                        p_DeliveryProfileID,
                        p_CollectedAmount,
                        v_CashSuccess,
                        v_CashMessage
                    );

                    IF v_CashSuccess = FALSE THEN
                        SET v_Message = CONCAT(v_Message, ' (Encaissement: ', v_CashMessage, ')');
                    END IF;
                END IF;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;
-- ====================================================
-- 1) CANCEL A PENDING DELIVERY (admin only)
-- ====================================================
DELIMITER $$

CREATE PROCEDURE SP_CancelDelivery (
    IN  p_DeliveryID   INT,
    IN  p_AdminUserID  INT,
    IN  p_Reason       NVARCHAR(500),
    OUT v_Success       BOOLEAN,
    OUT v_Message        VARCHAR(255)
)
BEGIN
    DECLARE v_DeliveryExists   INT DEFAULT 0;
    DECLARE v_CurrentStatusID  INT DEFAULT NULL;
    DECLARE v_PendingStatusID  INT DEFAULT NULL;
    DECLARE v_CancelledStatusID INT DEFAULT NULL;
    DECLARE v_ErrorMessage     VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_CancelDelivery', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de l''annulation de la livraison.';
    END;

    START TRANSACTION;

    SELECT COUNT(*), MAX(DeliveryStatusID)
    INTO v_DeliveryExists, v_CurrentStatusID
    FROM Deliveries
    WHERE DeliveryID = p_DeliveryID
    FOR UPDATE;

    IF v_DeliveryExists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Livraison introuvable.';
        ROLLBACK;
    ELSE
        SELECT DeliveryStatusID INTO v_PendingStatusID
        FROM DeliveryStatuses WHERE Code = 'pending' LIMIT 1;

        SELECT DeliveryStatusID INTO v_CancelledStatusID
        FROM DeliveryStatuses WHERE Code = 'cancelled' LIMIT 1;

        IF v_CurrentStatusID <> v_PendingStatusID THEN
            SET v_Success = FALSE;
            SET v_Message = 'Seules les livraisons en attente peuvent être annulées de cette manière.';
            ROLLBACK;
        ELSE
            UPDATE Deliveries
            SET DeliveryStatusID = v_CancelledStatusID,
                CancelledAt      = NOW(),
                Notes            = COALESCE(p_Reason, Notes),
                UpdatedAt        = NOW()
            WHERE DeliveryID = p_DeliveryID;

            INSERT INTO DeliveryStatusHistory (
                DeliveryID, DeliveryStatusID, Latitude, Longitude, ChangedAt
            )
            VALUES (
                p_DeliveryID, v_CancelledStatusID, NULL, NULL, NOW()
            );

            SET v_Success = TRUE;
            SET v_Message = 'Livraison annulée avec succès.';

            COMMIT;
        END IF;
    END IF;
END$$

DELIMITER ;
-- ====================================================
-- 2) ADMIN REMITS/COLLECTS CASH FROM A LIVREUR
--    (marks every outstanding CollectedAmount as remitted, in one shot)
-- ====================================================
DELIMITER $$

CREATE PROCEDURE SP_RemitLivreurCash (
    IN  p_DeliveryProfileID  INT,
    IN  p_AdminUserID        INT,
    IN  p_ExpectedAmount     DECIMAL(10,2),  -- NULL = skip the match check
    OUT v_Success             BOOLEAN,
    OUT v_Message              VARCHAR(255),
    OUT v_TotalRemitted         DECIMAL(10,2)
)
BEGIN
    DECLARE v_ProfileExists  INT DEFAULT 0;
    DECLARE v_OutstandingSum DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_OutstandingCnt INT DEFAULT 0;
    DECLARE v_ErrorMessage   VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_RemitLivreurCash', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la remise de l''encaissement.';
        SET v_TotalRemitted = 0.00;
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_ProfileExists
    FROM DeliveryProfiles
    WHERE DeliveryProfileID = p_DeliveryProfileID;

    IF v_ProfileExists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Profil livreur introuvable.';
        SET v_TotalRemitted = 0.00;
        ROLLBACK;
    ELSE
        -- lock every outstanding (collected, not yet remitted) row for this livreur
        SELECT COUNT(*), COALESCE(SUM(CollectedAmount), 0.00)
        INTO v_OutstandingCnt, v_OutstandingSum
        FROM DeliveryCashCollections
        WHERE DeliveryProfileID = p_DeliveryProfileID
          AND IsCollected = 1
          AND IsRemitted  = 0
        FOR UPDATE;

        IF v_OutstandingCnt = 0 THEN
            SET v_Success = FALSE;
            SET v_Message = 'Ce livreur n''a aucun encaissement en attente de remise.';
            SET v_TotalRemitted = 0.00;
            ROLLBACK;
        ELSEIF p_ExpectedAmount IS NOT NULL AND p_ExpectedAmount <> v_OutstandingSum THEN
            SET v_Success = FALSE;
            SET v_Message = CONCAT(
                'Le montant remis (', p_ExpectedAmount,
                ') ne correspond pas au montant dû (', v_OutstandingSum, ').'
            );
            SET v_TotalRemitted = 0.00;
            ROLLBACK;
        ELSE
            UPDATE DeliveryCashCollections
            SET IsRemitted     = 1,
                RemittedAmount = CollectedAmount,
                RemittedAt     = NOW(),
                RemittedTo     = p_AdminUserID,
                UpdatedAt      = NOW()
            WHERE DeliveryProfileID = p_DeliveryProfileID
              AND IsCollected = 1
              AND IsRemitted  = 0;

            SET v_Success = TRUE;
            SET v_Message = 'Encaissement remis avec succès.';
            SET v_TotalRemitted = v_OutstandingSum;

            COMMIT;
        END IF;
    END IF;
END$$

DELIMITER ;
-- ====================================================
-- 3) LIVREUR REQUESTS A WITHDRAWAL
-- ====================================================
DELIMITER $$

CREATE PROCEDURE SP_RequestDeliveryWithdraw (
    IN  p_DeliveryProfileID  INT,
    IN  p_Amount             DECIMAL(10,2),
    IN  p_PaymentMethodID    INT,
    OUT v_Success             BOOLEAN,
    OUT v_Message              VARCHAR(255),
    OUT v_WithdrawID            INT
)
BEGIN
    DECLARE v_WalletID       INT DEFAULT NULL;
    DECLARE v_Withdrawable   DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_IsLocked       TINYINT DEFAULT 0;
    DECLARE v_ErrorMessage   VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_RequestDeliveryWithdraw', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la demande de retrait.';
        SET v_WithdrawID = NULL;
    END;

    START TRANSACTION;

    SELECT DeliveryWalletID, WithdrawableBalance, IsLocked
    INTO v_WalletID, v_Withdrawable, v_IsLocked
    FROM DeliveryWallets
    WHERE DeliveryProfileID = p_DeliveryProfileID
    FOR UPDATE;

    IF v_WalletID IS NULL THEN
        SET v_Success = FALSE;
        SET v_Message = 'Portefeuille introuvable pour ce livreur.';
        ROLLBACK;
    ELSEIF v_IsLocked = 1 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Votre portefeuille est actuellement bloqué. Contactez le support.';
        ROLLBACK;
    ELSEIF p_Amount IS NULL OR p_Amount <= 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Le montant du retrait doit être supérieur à zéro.';
        ROLLBACK;
    ELSEIF p_Amount > v_Withdrawable THEN
        SET v_Success = FALSE;
        SET v_Message = 'Solde disponible insuffisant pour ce retrait.';
        ROLLBACK;
    ELSE
        UPDATE DeliveryWallets
        SET WithdrawableBalance = WithdrawableBalance - p_Amount,
            UpdatedAt           = NOW()
        WHERE DeliveryWalletID = v_WalletID;

        INSERT INTO DeliveryWithdrawHistory (
            DeliveryWalletID, PaymentMethodID, Amount, Status, RequestedAt
        )
        VALUES (
            v_WalletID, p_PaymentMethodID, p_Amount, 0, NOW()
        );

        SET v_WithdrawID = LAST_INSERT_ID();
        SET v_Success    = TRUE;
        SET v_Message    = 'Demande de retrait envoyée avec succès.';

        COMMIT;
    END IF;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS SP_ReleaseMaturedBankAccountHolds;

DELIMITER $$

CREATE PROCEDURE SP_ReleaseMaturedBankAccountHolds (
    OUT v_Success        BOOLEAN,
    OUT v_Message         VARCHAR(255),
    OUT v_ReleasedCount    INT
)
BEGIN
    DECLARE v_ErrorMessage VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_ReleaseMaturedBankAccountHolds', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la libération des fonds.';
        SET v_ReleasedCount = 0;
    END;

    START TRANSACTION;

    -- Move each matured hold's amount from Pending -> Withdrawable
    UPDATE BankAccounts ba
    INNER JOIN BankAccountHolds h ON h.BankAccountID = ba.BankAccountID
    SET ba.PendingBalance      = ba.PendingBalance - h.Amount,
        ba.WithdrawableBalance = ba.WithdrawableBalance + h.Amount,
        ba.UpdatedAt           = NOW()
    WHERE h.Status = 0
      AND h.ReleaseAt <= NOW();

    SELECT ROW_COUNT() INTO v_ReleasedCount;

    UPDATE BankAccountHolds
    SET Status     = 1,
        ReleasedAt = NOW()
    WHERE Status = 0
      AND ReleaseAt <= NOW();

    SET v_Success = TRUE;
    SET v_Message = 'Fonds libérés avec succès.';

    COMMIT;
END$$

DELIMITER ;
DROP PROCEDURE IF EXISTS SP_RequestVendorWithdraw;

DELIMITER $$

CREATE PROCEDURE SP_RequestVendorWithdraw (
    IN  p_VendorProfileID   INT,
    IN  p_Amount            DECIMAL(14,2),
    IN  p_PaymentMethodID   INT,
    OUT v_Success            BOOLEAN,
    OUT v_Message             VARCHAR(255),
    OUT v_WithdrawID           INT
)
BEGIN
    DECLARE v_BankAccountID  INT DEFAULT NULL;
    DECLARE v_Withdrawable   DECIMAL(14,2) DEFAULT 0.00;
    DECLARE v_IsLocked       TINYINT DEFAULT 0;
    DECLARE v_ErrorMessage   VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_RequestVendorWithdraw', v_ErrorMessage, NOW());

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la demande de retrait.';
        SET v_WithdrawID = NULL;
    END;

    START TRANSACTION;

    SELECT BankAccountID, WithdrawableBalance, IsLocked
    INTO v_BankAccountID, v_Withdrawable, v_IsLocked
    FROM BankAccounts
    WHERE VendorProfileID = p_VendorProfileID
    FOR UPDATE;

    IF v_BankAccountID IS NULL THEN
        SET v_Success = FALSE;
        SET v_Message = 'Compte bancaire introuvable pour ce vendeur.';
        ROLLBACK;
    ELSEIF v_IsLocked = 1 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Votre compte est actuellement bloqué. Contactez le support.';
        ROLLBACK;
    ELSEIF p_Amount IS NULL OR p_Amount <= 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Le montant du retrait doit être supérieur à zéro.';
        ROLLBACK;
    ELSEIF p_Amount > v_Withdrawable THEN
        SET v_Success = FALSE;
        SET v_Message = 'Solde disponible insuffisant pour ce retrait.';
        ROLLBACK;
    ELSE
        UPDATE BankAccounts
        SET WithdrawableBalance = WithdrawableBalance - p_Amount,
            UpdatedAt           = NOW()
        WHERE BankAccountID = v_BankAccountID;

        INSERT INTO WithdrawHistory (
            BankAccountID, PaymentMethodID, Amount, Status, RequestedAt
        )
        VALUES (
            v_BankAccountID, p_PaymentMethodID, p_Amount, 0, NOW()
        );

        SET v_WithdrawID = LAST_INSERT_ID();
        SET v_Success    = TRUE;
        SET v_Message    = 'Demande de retrait envoyée avec succès.';

        COMMIT;
    END IF;
END$$

DELIMITER ;
