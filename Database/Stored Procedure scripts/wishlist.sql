DELIMITER $$

CREATE PROCEDURE SP_CreateWishlist (
    IN v_UserPublicID VARCHAR(36),
    IN v_Name         VARCHAR(150),
    OUT v_WishListID  INT,
    OUT v_Success     BOOLEAN,
    OUT v_Message     VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_IsDefault TINYINT(1) DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_CreateWishlist', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID, 'Name', v_Name));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la création de la wishlist.';
        SET v_WishListID = NULL;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_WishListID = NULL;

    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        IF v_Name IS NULL OR TRIM(v_Name) = '' THEN
            SET v_Name = 'My Wishlist';
        END IF;

        -- La toute première wishlist d'un utilisateur devient automatiquement sa wishlist par défaut.
        SELECT COUNT(*) = 0 INTO v_IsDefault
        FROM WishLists
        WHERE UserID = v_UserID;

        INSERT INTO WishLists (UserID, Name, IsDefault)
        VALUES (v_UserID, v_Name, v_IsDefault);

        SET v_WishListID = LAST_INSERT_ID();
        SET v_Success = TRUE;
        SET v_Message = 'OK';
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_AddWishlistItem (
    IN v_UserPublicID    VARCHAR(36),
    IN v_WishListID      INT,
    IN v_ProductID       INT,
    OUT v_WishListItemID INT,
    OUT v_Success        BOOLEAN,
    OUT v_Message        VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_OwnerID INT DEFAULT NULL;
    DECLARE v_ProductExists INT DEFAULT 0;
    DECLARE v_AlreadyExists INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_AddWishlistItem', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID, 'WishListID', v_WishListID, 'ProductID', v_ProductID));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de l''ajout à la wishlist.';
        SET v_WishListItemID = NULL;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_WishListItemID = NULL;

    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        SELECT UserID INTO v_OwnerID FROM WishLists WHERE WishListID = v_WishListID;

        IF v_OwnerID IS NULL THEN
            SET v_Message = 'Wishlist introuvable';
        ELSEIF v_OwnerID != v_UserID THEN
            SET v_Message = 'Accès refusé : cette wishlist ne vous appartient pas.';
        ELSE
            SELECT COUNT(*) INTO v_ProductExists FROM Products WHERE ProductID = v_ProductID;

            IF v_ProductExists = 0 THEN
                SET v_Message = 'Produit introuvable';
            ELSE
                SELECT COUNT(*) INTO v_AlreadyExists
                FROM WishListItems
                WHERE WishListID = v_WishListID AND ProductID = v_ProductID;

                IF v_AlreadyExists > 0 THEN
                    SET v_Message = 'Ce produit est déjà dans cette wishlist.';
                ELSE
                    INSERT INTO WishListItems (WishListID, ProductID)
                    VALUES (v_WishListID, v_ProductID);

                    SET v_WishListItemID = LAST_INSERT_ID();
                    SET v_Success = TRUE;
                    SET v_Message = 'OK';
                END IF;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_RemoveWishlistItem (
    IN v_UserPublicID   VARCHAR(36),
    IN v_WishListItemID INT,
    OUT v_Success       BOOLEAN,
    OUT v_Message        VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_OwnerID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_RemoveWishlistItem', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID, 'WishListItemID', v_WishListItemID));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la suppression.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        SELECT wl.UserID INTO v_OwnerID
        FROM WishListItems wli
        JOIN WishLists wl ON wl.WishListID = wli.WishListID
        WHERE wli.WishListItemID = v_WishListItemID;

        IF v_OwnerID IS NULL THEN
            SET v_Message = 'Élément introuvable';
        ELSEIF v_OwnerID != v_UserID THEN
            SET v_Message = 'Accès refusé : cet élément ne vous appartient pas.';
        ELSE
            -- Suppression réelle, pas de soft-delete.
            DELETE FROM WishListItems WHERE WishListItemID = v_WishListItemID;

            SET v_Success = TRUE;
            SET v_Message = 'OK';
        END IF;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_DeleteWishlist (
    IN v_UserPublicID VARCHAR(36),
    IN v_WishListID   INT,
    OUT v_Success     BOOLEAN,
    OUT v_Message     VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_OwnerID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_DeleteWishlist', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID, 'WishListID', v_WishListID));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la suppression de la wishlist.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        SELECT UserID INTO v_OwnerID FROM WishLists WHERE WishListID = v_WishListID;

        IF v_OwnerID IS NULL THEN
            SET v_Message = 'Wishlist introuvable';
        ELSEIF v_OwnerID != v_UserID THEN
            SET v_Message = 'Accès refusé : cette wishlist ne vous appartient pas.';
        ELSE
            START TRANSACTION;

            DELETE FROM WishListItems WHERE WishListID = v_WishListID;
            DELETE FROM WishLists WHERE WishListID = v_WishListID;

            COMMIT;

            SET v_Success = TRUE;
            SET v_Message = 'OK';
        END IF;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_GetUserWishlists (
    IN v_UserPublicID VARCHAR(36),
    OUT v_Success     BOOLEAN,
    OUT v_Message     VARCHAR(255)
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
        VALUES ('SP_GetUserWishlists', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des wishlists.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
        SELECT NULL AS WishListID LIMIT 0;
        SELECT NULL AS WishListItemID LIMIT 0;
    ELSE
        SET v_Success = TRUE;
        SET v_Message = 'OK';

        -- Resultset 1 : les wishlists elles-mêmes, avec compteur d'items.
        SELECT
            wl.WishListID,
            wl.Name,
            wl.IsDefault,
            wl.CreatedAt,
            IFNULL((SELECT COUNT(*) FROM WishListItems wli WHERE wli.WishListID = wl.WishListID), 0) AS ItemCount
        FROM WishLists wl
        WHERE wl.UserID = v_UserID
        ORDER BY wl.IsDefault DESC, wl.CreatedAt DESC;

        -- Resultset 2 : tous les items de toutes les wishlists de l'utilisateur, avec les infos produit.
        SELECT
            wli.WishListItemID,
            wli.WishListID,
            p.ProductID,
            p.Name AS ProductName,
            pr.ResourcesPath AS ProductImage,
            p.BasePrice,
            b.Name AS BrandName,
            wli.CreatedAt
        FROM WishListItems wli
        JOIN WishLists wl ON wl.WishListID = wli.WishListID
        JOIN Products p ON p.ProductID = wli.ProductID
        LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND pr.ResourceRoleID = 2
        LEFT JOIN Brands b ON b.BrandID = p.BrandID
        WHERE wl.UserID = v_UserID
        ORDER BY wli.WishListID, wli.CreatedAt DESC;
    END IF;
END$$

DELIMITER ;