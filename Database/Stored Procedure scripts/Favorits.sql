CREATE TABLE IF NOT EXISTS ProductLikes (
    ProductLikeID INT NOT NULL AUTO_INCREMENT,
    UserID        INT NOT NULL,
    ProductID     INT NOT NULL,
    LikedAt       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ProductLikeID),
    KEY idx_ProductLikes_UserID (UserID),
    KEY idx_ProductLikes_ProductID (ProductID),
    UNIQUE KEY uq_ProductLikes_User_Product (UserID, ProductID)
);


DELIMITER $$

CREATE PROCEDURE SP_AddProductLike (
    IN v_UserPublicID   VARCHAR(36),
    IN v_ProductID      INT,
    OUT v_ProductLikeID INT,
    OUT v_Success       BOOLEAN,
    OUT v_Message       VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_ProductExists INT DEFAULT 0;
    DECLARE v_AlreadyLiked INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_AddProductLike', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID, 'ProductID', v_ProductID));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de l''ajout aux favoris.';
        SET v_ProductLikeID = NULL;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_ProductLikeID = NULL;

    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        SELECT COUNT(*) INTO v_ProductExists FROM Products WHERE ProductID = v_ProductID;

        IF v_ProductExists = 0 THEN
            SET v_Message = 'Produit introuvable';
        ELSE
            SELECT COUNT(*) INTO v_AlreadyLiked
            FROM ProductLikes
            WHERE UserID = v_UserID AND ProductID = v_ProductID;

            IF v_AlreadyLiked > 0 THEN
                SET v_Message = 'Vous aimez déjà ce produit.';
            ELSE
                INSERT INTO ProductLikes (UserID, ProductID)
                VALUES (v_UserID, v_ProductID);

                SET v_ProductLikeID = LAST_INSERT_ID();
                SET v_Success = TRUE;
                SET v_Message = 'OK';
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_RemoveProductLike (
    IN v_UserPublicID VARCHAR(36),
    IN v_ProductID    INT,
    OUT v_Success     BOOLEAN,
    OUT v_Message     VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_LikeExists INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES ('SP_RemoveProductLike', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID, 'ProductID', v_ProductID));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la suppression du favori.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        SELECT COUNT(*) INTO v_LikeExists
        FROM ProductLikes
        WHERE UserID = v_UserID AND ProductID = v_ProductID;

        IF v_LikeExists = 0 THEN
            SET v_Message = 'Ce produit n''est pas dans vos favoris.';
        ELSE
            -- Suppression réelle, pas de soft-delete.
            DELETE FROM ProductLikes WHERE UserID = v_UserID AND ProductID = v_ProductID;

            SET v_Success = TRUE;
            SET v_Message = 'OK';
        END IF;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE SP_GetUserProductLikes (
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
        VALUES ('SP_GetUserProductLikes', @p_sqlstate, @p_errno, @p_message,
                JSON_OBJECT('UserPublicID', v_UserPublicID));
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération des favoris.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
        SELECT NULL AS ProductLikeID LIMIT 0;
    ELSE
        SET v_Success = TRUE;
        SET v_Message = 'OK';

        SELECT
            pl.ProductLikeID,
            pl.ProductID,
            p.Name AS ProductName,
            pr.ResourcesPath AS ProductImage,
            p.BasePrice,
            b.Name AS BrandName,
            pl.LikedAt
        FROM ProductLikes pl
        JOIN Products p ON p.ProductID = pl.ProductID
        LEFT JOIN ProductResources pr ON pr.ProductID = p.ProductID AND pr.ResourceRoleID = 2
        LEFT JOIN Brands b ON b.BrandID = p.BrandID
        WHERE pl.UserID = v_UserID
        ORDER BY pl.LikedAt DESC;
    END IF;
END$$

DELIMITER ;