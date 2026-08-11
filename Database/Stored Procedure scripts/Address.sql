SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS SP_GetOrderShippingAddress;

DELIMITER $$
CREATE DEFINER=`root`@`%` PROCEDURE `SP_GetOrderShippingAddress`(
    IN  v_OrderID         INT,
    IN  v_VendorProfileID INT,   -- pass NULL to skip vendor-ownership check (e.g. admin/livreur use)
    OUT v_Success         BOOLEAN,
    OUT v_Message         VARCHAR(255)
)
BEGIN
    DECLARE v_AddressID  INT DEFAULT NULL;
    DECLARE v_IsVendorOnOrder INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetOrderShippingAddress',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('OrderID', v_OrderID, 'VendorProfileID', v_VendorProfileID)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération de l''adresse de livraison.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_OrderID IS NULL OR NOT EXISTS (SELECT 1 FROM Orders WHERE OrderID = v_OrderID) THEN
        SET v_Success = FALSE;
        SET v_Message = 'Commande introuvable.';

    ELSE

        -- If a vendor is asking, make sure they actually have items on this order
        IF v_VendorProfileID IS NOT NULL THEN
            SELECT COUNT(*) INTO v_IsVendorOnOrder
            FROM OrderItems
            WHERE OrderID = v_OrderID AND VendorProfileID = v_VendorProfileID;

            IF v_IsVendorOnOrder = 0 THEN
                SET v_Success = FALSE;
                SET v_Message = 'Non autorisé à consulter cette commande.';
            END IF;
        END IF;

        IF v_Message = '' THEN

            SELECT ShippingAddressID INTO v_AddressID
            FROM Orders
            WHERE OrderID = v_OrderID;

            IF v_AddressID IS NULL THEN
                SET v_Success = FALSE;
                SET v_Message = 'Aucune adresse de livraison associée à cette commande.';
            ELSE
                SET v_Success = TRUE;
                SET v_Message = 'OK';

                -- Public-safe columns only: no AddressID, UserID, or default flags exposed
                SELECT
                    FullName,
                    Phone,
                    Country,
                    Region,
                    City,
                    PostalCode,
                    AddressLine1,
                    AddressLine2,
                    Landmark,
                    Latitude,
                    Longitude
                FROM Addresses
                WHERE AddressID = v_AddressID;
            END IF;

        END IF;

    END IF;

END $$
DELIMITER ;

-- ============================================================
-- Manual tests
-- ============================================================
-- Vendor checking their own order:
-- CALL SP_GetOrderShippingAddress(101, 5, @success, @message);
-- SELECT @success, @message;

-- Admin / livreur (no vendor scoping):
-- CALL SP_GetOrderShippingAddress(101, NULL, @success, @message);
-- SELECT @success, @message;


SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS SP_GetUserShippingAddress;

DELIMITER $$
CREATE DEFINER=`root`@`%` PROCEDURE `SP_GetUserShippingAddress`(
    IN  v_UserID  INT,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE v_AddressID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetUserShippingAddress',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('UserID', v_UserID)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération de l''adresse de livraison.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF v_UserID IS NULL OR NOT EXISTS (SELECT 1 FROM Users WHERE UserID = v_UserID AND IsDeleted = 0) THEN
        SET v_Success = FALSE;
        SET v_Message = 'Utilisateur invalide.';
    ELSE

        -- Prefer the address explicitly marked as default shipping
        SELECT AddressID INTO v_AddressID
        FROM Addresses
        WHERE UserID = v_UserID AND IsDefaultShipping = 1
        LIMIT 1;

        -- Fallback: most recently added address, if no default was ever set
        IF v_AddressID IS NULL THEN
            SELECT AddressID INTO v_AddressID
            FROM Addresses
            WHERE UserID = v_UserID
            ORDER BY CreatedAt DESC
            LIMIT 1;
        END IF;

        IF v_AddressID IS NULL THEN
            SET v_Success = FALSE;
            SET v_Message = 'Aucune adresse de livraison trouvée pour cet utilisateur.';
        ELSE
            SET v_Success = TRUE;
            SET v_Message = 'OK';

            -- Public-safe columns only: no AddressID, UserID, or default flags exposed
            SELECT
                FullName,
                Phone,
                Country,
                Region,
                City,
                PostalCode,
                AddressLine1,
                AddressLine2,
                Landmark,
                Latitude,
                Longitude
            FROM Addresses
            WHERE AddressID = v_AddressID;
        END IF;

    END IF;

END $$
DELIMITER ;

-- ============================================================
-- Manual test
-- ============================================================
-- CALL SP_GetUserShippingAddress(1, @success, @message);
-- SELECT @success, @message;


SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ============================================================
-- SP_UpdateAddress
-- NOTE: repository's SQL string currently has 13 "?" placeholders
-- but binds 14 values. Add one more "?" before @v_Success in
-- AddressRepository::update() to match this signature.
-- ============================================================
DROP PROCEDURE IF EXISTS SP_UpdateAddress;

DELIMITER $$
CREATE DEFINER=`root`@`%` PROCEDURE `SP_UpdateAddress`(
    IN  v_AddressID          INT,
    IN  v_UserID             INT,
    IN  v_FullName           NVARCHAR(255),
    IN  v_Phone              NVARCHAR(30),
    IN  v_Country            NVARCHAR(100),
    IN  v_Region             NVARCHAR(100),
    IN  v_City               NVARCHAR(100),
    IN  v_PostalCode         NVARCHAR(20),
    IN  v_AddressLine1       NVARCHAR(255),
    IN  v_AddressLine2       NVARCHAR(255),
    IN  v_Landmark           NVARCHAR(255),
    IN  v_Latitude           DECIMAL(10,7),
    IN  v_Longitude          DECIMAL(10,7),
    IN  v_IsDefaultShipping  BIT,
    OUT v_Success            BOOLEAN,
    OUT v_Message            VARCHAR(255)
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
            'SP_UpdateAddress',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('AddressID', v_AddressID, 'UserID', v_UserID)
        );
        ROLLBACK;
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la mise à jour de l''adresse.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    SELECT COUNT(*) INTO v_Exists
    FROM Addresses
    WHERE AddressID = v_AddressID AND UserID = v_UserID;

    IF v_Exists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Adresse introuvable.';
    ELSEIF v_FullName IS NULL OR TRIM(v_FullName) = '' THEN
        SET v_Success = FALSE;
        SET v_Message = 'Le nom complet est requis.';
    ELSEIF v_AddressLine1 IS NULL OR TRIM(v_AddressLine1) = '' THEN
        SET v_Success = FALSE;
        SET v_Message = 'L''adresse (ligne 1) est requise.';
    ELSEIF v_City IS NULL OR TRIM(v_City) = '' THEN
        SET v_Success = FALSE;
        SET v_Message = 'La ville est requise.';
    ELSEIF v_Country IS NULL OR TRIM(v_Country) = '' THEN
        SET v_Success = FALSE;
        SET v_Message = 'Le pays est requis.';
    ELSE

        START TRANSACTION;

        SET v_IsDefaultShipping = IFNULL(v_IsDefaultShipping, 0);

        -- If this address becomes default shipping, unset any other default for this user
        IF v_IsDefaultShipping = 1 THEN
            UPDATE Addresses
            SET IsDefaultShipping = 0
            WHERE UserID = v_UserID
              AND AddressID <> v_AddressID
              AND IsDefaultShipping = 1;
        END IF;

        UPDATE Addresses
        SET
            FullName          = v_FullName,
            Phone             = v_Phone,
            Country           = v_Country,
            Region            = v_Region,
            City              = v_City,
            PostalCode        = v_PostalCode,
            AddressLine1      = v_AddressLine1,
            AddressLine2      = v_AddressLine2,
            Landmark          = v_Landmark,
            Latitude          = v_Latitude,
            Longitude         = v_Longitude,
            IsDefaultShipping = v_IsDefaultShipping
        WHERE AddressID = v_AddressID
          AND UserID    = v_UserID;

        COMMIT;

        SET v_Success = TRUE;
        SET v_Message = 'OK';

    END IF;

END $$
DELIMITER ;


-- ============================================================
-- SP_DeleteAddress
-- ============================================================
DROP PROCEDURE IF EXISTS SP_DeleteAddress;

DELIMITER $$
CREATE DEFINER=`root`@`%` PROCEDURE `SP_DeleteAddress`(
    IN  v_AddressID INT,
    IN  v_UserID    INT,
    OUT v_Success   BOOLEAN,
    OUT v_Message   VARCHAR(255)
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
            'SP_DeleteAddress',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('AddressID', v_AddressID, 'UserID', v_UserID)
        );
        ROLLBACK;
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la suppression de l''adresse.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    SELECT COUNT(*) INTO v_Exists
    FROM Addresses
    WHERE AddressID = v_AddressID AND UserID = v_UserID;

    IF v_Exists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Adresse introuvable.';
    ELSE

        START TRANSACTION;

        DELETE FROM Addresses
        WHERE AddressID = v_AddressID
          AND UserID    = v_UserID;

        COMMIT;

        SET v_Success = TRUE;
        SET v_Message = 'OK';

    END IF;

END $$
DELIMITER ;


-- ============================================================
-- SP_SetDefaultShippingAddress
-- ============================================================
DROP PROCEDURE IF EXISTS SP_SetDefaultShippingAddress;

DELIMITER $$
CREATE DEFINER=`root`@`%` PROCEDURE `SP_SetDefaultShippingAddress`(
    IN  v_AddressID INT,
    IN  v_UserID    INT,
    OUT v_Success   BOOLEAN,
    OUT v_Message   VARCHAR(255)
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
            'SP_SetDefaultShippingAddress',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('AddressID', v_AddressID, 'UserID', v_UserID)
        );
        ROLLBACK;
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la définition de l''adresse par défaut.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    SELECT COUNT(*) INTO v_Exists
    FROM Addresses
    WHERE AddressID = v_AddressID AND UserID = v_UserID;

    IF v_Exists = 0 THEN
        SET v_Success = FALSE;
        SET v_Message = 'Adresse introuvable.';
    ELSE

        START TRANSACTION;

        UPDATE Addresses
        SET IsDefaultShipping = 0
        WHERE UserID = v_UserID
          AND AddressID <> v_AddressID
          AND IsDefaultShipping = 1;

        UPDATE Addresses
        SET IsDefaultShipping = 1
        WHERE AddressID = v_AddressID
          AND UserID    = v_UserID;

        COMMIT;

        SET v_Success = TRUE;
        SET v_Message = 'OK';

    END IF;

END $$
DELIMITER ;


-- ============================================================
-- Manual tests
-- ============================================================
-- CALL SP_UpdateAddress(1, 1, 'Mohammed Alami', '+212600000000', 'Maroc', 'Casablanca-Settat', 'Casablanca', '20000', '12 Rue Hassan II', 'Appt 4', 'Près de la pharmacie', 33.5731104, -7.5898434, 1, @success, @message);
-- SELECT @success, @message;

-- CALL SP_DeleteAddress(1, 1, @success, @message);
-- SELECT @success, @message;

-- CALL SP_SetDefaultShippingAddress(2, 1, @success, @message);
-- SELECT @success, @message;


SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS SP_AddAddress;

DELIMITER $$
CREATE DEFINER=`root`@`%` PROCEDURE `SP_AddAddress`(
    IN  v_UserID            INT,
    IN  v_FullName          NVARCHAR(255),
    IN  v_Phone             NVARCHAR(30),
    IN  v_Country            NVARCHAR(100),
    IN  v_Region             NVARCHAR(100),
    IN  v_City               NVARCHAR(100),
    IN  v_PostalCode         NVARCHAR(20),
    IN  v_AddressLine1       NVARCHAR(255),
    IN  v_AddressLine2       NVARCHAR(255),
    IN  v_Landmark           NVARCHAR(255),
    IN  v_Latitude           DECIMAL(10,7),
    IN  v_Longitude          DECIMAL(10,7),
    IN  v_IsDefaultShipping  BIT,
    OUT v_Success            BOOLEAN,
    OUT v_Message            VARCHAR(255),
    OUT v_AddressID          INT
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
            'SP_AddAddress',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'UserID',           v_UserID,
                'FullName',         v_FullName,
                'City',             v_City,
                'Country',          v_Country,
                'IsDefaultShipping', v_IsDefaultShipping
            )
        );
        ROLLBACK;
        SET v_Success   = FALSE;
        SET v_Message   = 'Une erreur est survenue lors de l''ajout de l''adresse.';
        SET v_AddressID = NULL;
    END;

    SET v_Success   = FALSE;
    SET v_Message   = '';
    SET v_AddressID = NULL;

    -- ===== Validation =====
    IF v_UserID IS NULL OR NOT EXISTS (SELECT 1 FROM Users WHERE UserID = v_UserID AND IsDeleted = 0) THEN
        SET v_Success = FALSE;
        SET v_Message = 'Utilisateur invalide.';
    ELSEIF v_FullName IS NULL OR TRIM(v_FullName) = '' THEN
        SET v_Success = FALSE;
        SET v_Message = 'Le nom complet est requis.';
    ELSEIF v_AddressLine1 IS NULL OR TRIM(v_AddressLine1) = '' THEN
        SET v_Success = FALSE;
        SET v_Message = 'L''adresse (ligne 1) est requise.';
    ELSEIF v_City IS NULL OR TRIM(v_City) = '' THEN
        SET v_Success = FALSE;
        SET v_Message = 'La ville est requise.';
    ELSEIF v_Country IS NULL OR TRIM(v_Country) = '' THEN
        SET v_Success = FALSE;
        SET v_Message = 'Le pays est requis.';
    ELSE

        START TRANSACTION;

        SET v_IsDefaultShipping = IFNULL(v_IsDefaultShipping, 0);

        -- IsDefaultBilling is forced to 0 for now (billing address feature not active yet)

        -- If this address is set as default shipping, unset any previous default shipping for this user
        IF v_IsDefaultShipping = 1 THEN
            UPDATE Addresses
            SET IsDefaultShipping = 0
            WHERE UserID = v_UserID AND IsDefaultShipping = 1;
        END IF;

        INSERT INTO Addresses (
            UserID, FullName, Phone, Country, Region, City, PostalCode,
            AddressLine1, AddressLine2, Landmark, Latitude, Longitude,
            IsDefaultBilling, IsDefaultShipping, CreatedAt
        )
        VALUES (
            v_UserID, v_FullName, v_Phone, v_Country, v_Region, v_City, v_PostalCode,
            v_AddressLine1, v_AddressLine2, v_Landmark, v_Latitude, v_Longitude,
            0, v_IsDefaultShipping, NOW()
        );

        SET v_AddressID = LAST_INSERT_ID();

        COMMIT;

        SET v_Success = TRUE;
        SET v_Message = 'OK';

    END IF;

END $$
DELIMITER ;

-- ============================================================
-- Manual test
-- ============================================================
-- CALL SP_AddAddress(
--     1, 'Mohammed Alami', '+212600000000',
--     'Maroc', 'Casablanca-Settat', 'Casablanca', '20000',
--     '12 Rue Hassan II', 'Appt 4', 'Près de la pharmacie',
--     33.5731104, -7.5898434,
--     1,
--     @success, @message, @addressId
-- );
-- SELECT @success, @message, @addressId;