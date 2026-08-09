DELIMITER $$

-- =====================================================================
-- SP_InsertStoreRating
-- =====================================================================
DROP PROCEDURE IF EXISTS SP_InsertStoreRating $$

CREATE PROCEDURE SP_InsertStoreRating(
    IN  p_UserPublicID    VARCHAR(36),
    IN  p_VendorProfileID INT,
    IN  p_Rating          TINYINT,
    IN  p_Comment         TEXT,
    OUT v_Success         BOOLEAN,
    OUT v_Message         VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_UserID         INT DEFAULT NULL;
    DECLARE v_VendorExists   INT DEFAULT 0;
    DECLARE v_NewAvgRating   DECIMAL(3,2);
    DECLARE v_NewReviewCount INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_InsertStoreRating',
            @p_sqlstate, @p_errno, @p_message,
            JSON_OBJECT(
                'UserPublicID',    p_UserPublicID,
                'VendorProfileID', p_VendorProfileID,
                'Rating',          p_Rating
            )
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la soumission de l\'avis.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF p_UserPublicID IS NULL THEN
        SET v_Message = 'UserPublicID est requis.';
        LEAVE main_block;
    END IF;

    IF p_VendorProfileID IS NULL THEN
        SET v_Message = 'VendorProfileID est requis.';
        LEAVE main_block;
    END IF;

    IF p_Rating IS NULL OR p_Rating NOT BETWEEN 1 AND 5 THEN
        SET v_Message = 'La note doit être comprise entre 1 et 5.';
        LEAVE main_block;
    END IF;

    SELECT UserID INTO v_UserID
    FROM   Users
    WHERE  PublicID = p_UserPublicID
    LIMIT  1;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable.';
        LEAVE main_block;
    END IF;

    SELECT COUNT(*) INTO v_VendorExists
    FROM   VendorProfiles
    WHERE  VendorProfileID = p_VendorProfileID;

    IF v_VendorExists = 0 THEN
        SET v_Message = 'Profil vendeur introuvable.';
        LEAVE main_block;
    END IF;

    IF EXISTS (
        SELECT 1 FROM VendorProfiles
        WHERE VendorProfileID = p_VendorProfileID AND UserID = v_UserID
    ) THEN
        SET v_Message = 'Vous ne pouvez pas évaluer votre propre boutique.';
        LEAVE main_block;
    END IF;

    START TRANSACTION;

        -- Insert or update if already rated
        INSERT INTO UserStoreRatings (VendorProfileID, UserID, Rating, Comment, DeletedAt)
        VALUES (p_VendorProfileID, v_UserID, p_Rating, p_Comment, NULL)
        ON DUPLICATE KEY UPDATE
            Rating    = VALUES(Rating),
            Comment   = VALUES(Comment),
            DeletedAt = NULL;

        -- Sync average Rating + ReviewCount
        SELECT ROUND(AVG(Rating), 2), COUNT(*)
        INTO   v_NewAvgRating, v_NewReviewCount
        FROM   UserStoreRatings
        WHERE  VendorProfileID = p_VendorProfileID
          AND  DeletedAt IS NULL;

        UPDATE VendorProfiles
        SET    Rating      = v_NewAvgRating,
               ReviewCount = v_NewReviewCount,
               UpdatedAt   = NOW()
        WHERE  VendorProfileID = p_VendorProfileID;

    COMMIT;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

END main_block $$

DELIMITER $$

-- =====================================================================
-- SP_UpdateStoreRating
-- =====================================================================
DROP PROCEDURE IF EXISTS SP_UpdateStoreRating $$

CREATE PROCEDURE SP_UpdateStoreRating(
    IN  p_UserPublicID    VARCHAR(36),
    IN  p_VendorProfileID INT,
    IN  p_Rating          TINYINT,
    IN  p_Comment         TEXT,
    OUT v_Success         BOOLEAN,
    OUT v_Message         VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_UserID         INT DEFAULT NULL;
    DECLARE v_RatingExists   INT DEFAULT 0;
    DECLARE v_IsOwner        INT DEFAULT 0;
    DECLARE v_NewAvgRating   DECIMAL(3,2);
    DECLARE v_NewReviewCount INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_UpdateStoreRating',
            @p_sqlstate, @p_errno, @p_message,
            JSON_OBJECT(
                'UserPublicID',    p_UserPublicID,
                'VendorProfileID', p_VendorProfileID,
                'Rating',          p_Rating
            )
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la mise à jour de l\'avis.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF p_UserPublicID IS NULL THEN
        SET v_Message = 'UserPublicID est requis.';
        LEAVE main_block;
    END IF;

    IF p_VendorProfileID IS NULL THEN
        SET v_Message = 'VendorProfileID est requis.';
        LEAVE main_block;
    END IF;

    IF p_Rating IS NULL OR p_Rating NOT BETWEEN 1 AND 5 THEN
        SET v_Message = 'La note doit être comprise entre 1 et 5.';
        LEAVE main_block;
    END IF;

    -- Resolve UserID
    SELECT UserID INTO v_UserID
    FROM   Users
    WHERE  PublicID = p_UserPublicID
    LIMIT  1;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable.';
        LEAVE main_block;
    END IF;

    -- Check the rating exists at all (not deleted, for this vendor)
    SELECT COUNT(*) INTO v_RatingExists
    FROM   UserStoreRatings
    WHERE  VendorProfileID = p_VendorProfileID
      AND  DeletedAt       IS NULL;

    IF v_RatingExists = 0 THEN
        SET v_Message = 'Aucun avis trouvé pour cette boutique.';
        LEAVE main_block;
    END IF;

    -- Ownership check: the rating must belong to this user
    SELECT COUNT(*) INTO v_IsOwner
    FROM   UserStoreRatings
    WHERE  UserID          = v_UserID
      AND  VendorProfileID = p_VendorProfileID
      AND  DeletedAt       IS NULL;

    IF v_IsOwner = 0 THEN
        SET v_Message = 'Vous n\'êtes pas autorisé à modifier cet avis.';
        LEAVE main_block;
    END IF;

    START TRANSACTION;

        UPDATE UserStoreRatings
        SET    Rating    = p_Rating,
               Comment   = p_Comment,
               DeletedAt = NULL
        WHERE  UserID          = v_UserID
          AND  VendorProfileID = p_VendorProfileID;

        SELECT ROUND(AVG(Rating), 2), COUNT(*)
        INTO   v_NewAvgRating, v_NewReviewCount
        FROM   UserStoreRatings
        WHERE  VendorProfileID = p_VendorProfileID
          AND  DeletedAt IS NULL;

        UPDATE VendorProfiles
        SET    Rating      = v_NewAvgRating,
               ReviewCount = v_NewReviewCount,
               UpdatedAt   = NOW()
        WHERE  VendorProfileID = p_VendorProfileID;

    COMMIT;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

END main_block $$

-- =====================================================================
-- SP_DeleteStoreRating
-- =====================================================================
DROP PROCEDURE IF EXISTS SP_DeleteStoreRating $$

CREATE PROCEDURE SP_DeleteStoreRating(
    IN  p_UserPublicID    VARCHAR(36),
    IN  p_VendorProfileID INT,
    OUT v_Success         BOOLEAN,
    OUT v_Message         VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_UserID         INT DEFAULT NULL;
    DECLARE v_RatingExists   INT DEFAULT 0;
    DECLARE v_IsOwner        INT DEFAULT 0;
    DECLARE v_NewAvgRating   DECIMAL(3,2);
    DECLARE v_NewReviewCount INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_DeleteStoreRating',
            @p_sqlstate, @p_errno, @p_message,
            JSON_OBJECT(
                'UserPublicID',    p_UserPublicID,
                'VendorProfileID', p_VendorProfileID
            )
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la suppression de l\'avis.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF p_UserPublicID IS NULL THEN
        SET v_Message = 'UserPublicID est requis.';
        LEAVE main_block;
    END IF;

    IF p_VendorProfileID IS NULL THEN
        SET v_Message = 'VendorProfileID est requis.';
        LEAVE main_block;
    END IF;

    -- Resolve UserID
    SELECT UserID INTO v_UserID
    FROM   Users
    WHERE  PublicID = p_UserPublicID
    LIMIT  1;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable.';
        LEAVE main_block;
    END IF;

    -- Check the rating exists at all (not deleted, for this vendor)
    SELECT COUNT(*) INTO v_RatingExists
    FROM   UserStoreRatings
    WHERE  VendorProfileID = p_VendorProfileID
      AND  DeletedAt       IS NULL;

    IF v_RatingExists = 0 THEN
        SET v_Message = 'Aucun avis actif trouvé pour cette boutique.';
        LEAVE main_block;
    END IF;

    -- Ownership check: the rating must belong to this user
    SELECT COUNT(*) INTO v_IsOwner
    FROM   UserStoreRatings
    WHERE  UserID          = v_UserID
      AND  VendorProfileID = p_VendorProfileID
      AND  DeletedAt       IS NULL;

    IF v_IsOwner = 0 THEN
        SET v_Message = 'Vous n\'êtes pas autorisé à supprimer cet avis.';
        LEAVE main_block;
    END IF;

    START TRANSACTION;

        UPDATE UserStoreRatings
        SET    DeletedAt = NOW()
        WHERE  UserID          = v_UserID
          AND  VendorProfileID = p_VendorProfileID;

        SELECT ROUND(AVG(Rating), 2), COUNT(*)
        INTO   v_NewAvgRating, v_NewReviewCount
        FROM   UserStoreRatings
        WHERE  VendorProfileID = p_VendorProfileID
          AND  DeletedAt IS NULL;

        UPDATE VendorProfiles
        SET    Rating      = IFNULL(v_NewAvgRating, 0),
               ReviewCount = v_NewReviewCount,
               UpdatedAt   = NOW()
        WHERE  VendorProfileID = p_VendorProfileID;

    COMMIT;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

END main_block $$

DELIMITER ;
DELIMITER $$
-- =====================================================================
-- SP_GetStoreRatings
-- =====================================================================
DROP PROCEDURE IF EXISTS SP_GetStoreRatings $$

CREATE PROCEDURE SP_GetStoreRatings(
    IN  p_VendorProfileID INT,
    IN  p_PageNumber      INT,
    IN  p_PageSize        INT,
    OUT v_TotalCount      INT,
    OUT v_AverageRating   DECIMAL(3,2),
    OUT v_Success         BOOLEAN,
    OUT v_Message         VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_Offset      INT DEFAULT 0;
    DECLARE v_VendorExists INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_GetStoreRatings',
            @p_sqlstate, @p_errno, @p_message,
            JSON_OBJECT('VendorProfileID', p_VendorProfileID)
        );
        SET v_Success       = FALSE;
        SET v_Message       = 'Une erreur est survenue lors de la récupération des avis.';
        SET v_TotalCount    = 0;
        SET v_AverageRating = 0;
    END;

    SET v_Success       = FALSE;
    SET v_Message       = '';
    SET v_TotalCount    = 0;
    SET v_AverageRating = 0;

    IF p_VendorProfileID IS NULL THEN
        SET v_Message = 'VendorProfileID est requis.';
        LEAVE main_block;
    END IF;

    SELECT COUNT(*) INTO v_VendorExists
    FROM   VendorProfiles
    WHERE  VendorProfileID = p_VendorProfileID;

    IF v_VendorExists = 0 THEN
        SET v_Message = 'Profil vendeur introuvable.';
        LEAVE main_block;
    END IF;

    IF p_PageNumber IS NULL OR p_PageNumber < 1 THEN SET p_PageNumber = 1; END IF;
    IF p_PageSize IS NULL OR p_PageSize < 1 THEN
        SET p_PageSize = 20;
    ELSEIF p_PageSize > 100 THEN
        SET p_PageSize = 100;
    END IF;

    SET v_Offset = (p_PageNumber - 1) * p_PageSize;

    SELECT COUNT(*), ROUND(AVG(Rating), 2)
    INTO   v_TotalCount, v_AverageRating
    FROM   UserStoreRatings
    WHERE  VendorProfileID = p_VendorProfileID
      AND  DeletedAt IS NULL;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    SELECT
        usr.RatingID,
        usr.Rating,
        usr.Comment,
        CONCAT(u.FirstName, ' ', u.LastName) AS CommenterName,
        u.AvatarURL                          AS CommenterAvatar
    FROM  UserStoreRatings usr
    INNER JOIN Users u ON u.UserID = usr.UserID
    WHERE usr.VendorProfileID = p_VendorProfileID
      AND usr.DeletedAt        IS NULL
    ORDER BY usr.RatingID DESC
    LIMIT  p_PageSize
    OFFSET v_Offset;

END main_block $$

DELIMITER ;