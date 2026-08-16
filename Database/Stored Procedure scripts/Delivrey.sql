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


DELIMITER $$

CREATE PROCEDURE SP_GetDeliveryHistoryByProfile (
    IN  p_DeliveryProfileID   INT,
    IN  p_StatusCode           VARCHAR(50),   -- NULL = all statuses
    IN  p_DateFrom               DATE,          -- NULL = no lower bound
    IN  p_DateTo                  DATE,          -- NULL = no upper bound
    IN  p_Page                     INT,
    IN  p_PerPage                   INT,
    OUT v_Success                    BOOLEAN,
    OUT v_Message                     VARCHAR(255),
    OUT v_TotalCount                   INT
)
BEGIN
    DECLARE v_ProfileExists    INT DEFAULT 0;
    DECLARE v_Offset            INT DEFAULT 0;
    DECLARE v_ErrorMessage      VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_ErrorMessage = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
        VALUES ('SP_GetDeliveryHistoryByProfile', v_ErrorMessage, NOW());

        SET v_Success    = FALSE;
        SET v_Message    = 'Une erreur est survenue lors de la récupération de l''historique.';
        SET v_TotalCount = 0;
    END;

    SELECT COUNT(*) INTO v_ProfileExists
    FROM DeliveryProfiles
    WHERE DeliveryProfileID = p_DeliveryProfileID;

    IF v_ProfileExists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Profil livreur introuvable.';
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
        WHERE d.DeliveryProfileID = p_DeliveryProfileID
          AND (p_StatusCode IS NULL OR p_StatusCode = '' OR ds.Code = p_StatusCode)
          AND (p_DateFrom IS NULL OR DATE(d.RequestedAt) >= p_DateFrom)
          AND (p_DateTo   IS NULL OR DATE(d.RequestedAt) <= p_DateTo);

        -- ------------------------------------------------
        -- Page of results, newest first
        -- ------------------------------------------------
        SELECT
            d.DeliveryID,
            d.OrderID,
            d.VendorProfileID,
            vp.StoreName,

            ds.Code   AS StatusCode,
            ds.Name   AS StatusName,

            d.DeliveryFee,
            (SELECT COUNT(*) FROM DeliveryItems di WHERE di.DeliveryID = d.DeliveryID) AS TotalItems,

            af.City   AS FromCity,
            af.Region AS FromRegion,
            af.Country AS FromCountry,

            at.City   AS ToCity,
            at.Region AS ToRegion,
            at.Country AS ToCountry,

            d.RequestedAt,
            d.AcceptedAt,
            d.PickedUpAt,
            d.DeliveredAt,
            d.CancelledAt

        FROM Deliveries d
        INNER JOIN DeliveryStatuses ds ON ds.DeliveryStatusID = d.DeliveryStatusID
        INNER JOIN Addresses af        ON af.AddressID = d.AddressFromID
        INNER JOIN Addresses at        ON at.AddressID = d.AddressToID
        INNER JOIN VendorProfiles vp   ON vp.VendorProfileID = d.VendorProfileID
        WHERE d.DeliveryProfileID = p_DeliveryProfileID
          AND (p_StatusCode IS NULL OR p_StatusCode = '' OR ds.Code = p_StatusCode)
          AND (p_DateFrom IS NULL OR DATE(d.RequestedAt) >= p_DateFrom)
          AND (p_DateTo   IS NULL OR DATE(d.RequestedAt) <= p_DateTo)
        ORDER BY d.RequestedAt DESC
        LIMIT p_PerPage OFFSET v_Offset;

        SET v_Success = TRUE;
        SET v_Message = 'Historique récupéré avec succès.';
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
