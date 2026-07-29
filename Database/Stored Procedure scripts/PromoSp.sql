DELIMITER $$

CREATE PROCEDURE SP_GetPromotionDiscountTypes()
BEGIN
    SELECT DiscountTypeID, Code, Label
    FROM PromotionDiscountTypes
    WHERE IsActive = 1
    ORDER BY DiscountTypeID;
END$$

DELIMITER ;

DELIMITER $$
CREATE PROCEDURE SP_GetPromotionScopeTypes()
BEGIN
    SELECT ScopeTypeID, Code, Label FROM PromotionScopeTypes WHERE IsActive = 1 ORDER BY ScopeTypeID;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE SP_GetPromotionStatuses()
BEGIN
    SELECT StatusID, Code, Label FROM PromotionStatuses WHERE IsActive = 1 ORDER BY StatusID;
END$$
DELIMITER ;
DELIMITER $$

CREATE PROCEDURE SP_CreatePromotionForProduct(
    IN v_UserPublicID VARCHAR(36),
    IN v_ProductID INT,
    IN v_Name VARCHAR(150),
    IN v_Description VARCHAR(500),
    IN v_PromoCode VARCHAR(50),
    IN v_DiscountTypeCode VARCHAR(30),
    IN v_DiscountValue DECIMAL(10,2),
    IN v_MaxDiscountAmount DECIMAL(10,2),
    IN v_MinOrderAmount DECIMAL(10,2),
    IN v_UsageLimitTotal INT UNSIGNED,
    IN v_UsageLimitPerUser INT UNSIGNED,
    IN v_StartDate DATETIME,
    IN v_EndDate DATETIME,
    OUT v_PromotionID INT UNSIGNED,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT;
    DECLARE v_VendorProfileID INT;
    DECLARE v_OwnerVendorID INT;
    DECLARE v_DiscountTypeID INT UNSIGNED;
    DECLARE v_ScopeTypeID INT UNSIGNED;
    DECLARE v_StatusID INT UNSIGNED;
    DECLARE v_DuplicateCode INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_CreatePromotionForProduct',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('UserPublicID', v_UserPublicID, 'ProductID', v_ProductID, 'PromoCode', v_PromoCode)
        );

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la création de la promotion.';
        SET v_PromotionID = NULL;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_PromotionID = NULL;

    -- Résolution utilisateur
    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        -- Résolution profil vendeur
        SELECT VendorProfileID INTO v_VendorProfileID
        FROM VendorProfiles WHERE UserID = v_UserID;

        IF v_VendorProfileID IS NULL THEN
            SET v_Message = 'Profil vendeur introuvable pour cet utilisateur';
        ELSE
            -- Vérification de propriété du produit
            SELECT VendorID INTO v_OwnerVendorID
            FROM Products WHERE ProductID = v_ProductID;

            IF v_OwnerVendorID IS NULL THEN
                SET v_Message = 'Produit introuvable';
            ELSEIF v_OwnerVendorID <> v_VendorProfileID THEN
                SET v_Message = 'Accès refusé : vous n''êtes pas propriétaire de ce produit';
            ELSE
                -- Résolution du DiscountTypeID
                SELECT DiscountTypeID INTO v_DiscountTypeID
                FROM PromotionDiscountTypes
                WHERE Code = v_DiscountTypeCode AND IsActive = 1;

                IF v_DiscountTypeID IS NULL THEN
                    SET v_Message = 'Type de réduction invalide';
                ELSEIF v_DiscountValue IS NULL OR v_DiscountValue <= 0 THEN
                    SET v_Message = 'La valeur de la réduction doit être supérieure à 0';
                ELSEIF v_DiscountTypeCode = 'PERCENTAGE' AND v_DiscountValue > 100 THEN
                    SET v_Message = 'Le pourcentage de réduction ne peut pas dépasser 100';
                ELSEIF v_MinOrderAmount IS NOT NULL AND v_MinOrderAmount < 0 THEN
                    SET v_Message = 'Le montant minimum de commande doit être supérieur ou égal à 0';
                ELSEIF v_StartDate IS NULL OR v_EndDate IS NULL THEN
                    SET v_Message = 'Les dates de début et de fin sont obligatoires';
                ELSEIF v_EndDate <= v_StartDate THEN
                    SET v_Message = 'La date de fin doit être postérieure à la date de début';
                ELSE
                    -- Unicité du PromoCode (si fourni)
                    IF v_PromoCode IS NOT NULL THEN
                        SELECT COUNT(*) INTO v_DuplicateCode
                        FROM Promotions
                        WHERE PromoCode = v_PromoCode AND DeletedAt IS NULL;
                    ELSE
                        SET v_DuplicateCode = 0;
                    END IF;

                    IF v_DuplicateCode > 0 THEN
                        SET v_Message = 'Ce code promo est déjà utilisé';
                    ELSE
                        -- Résolution ScopeTypeID = PRODUCT, StatusID = PENDING
                        SELECT ScopeTypeID INTO v_ScopeTypeID
                        FROM PromotionScopeTypes WHERE Code = 'PRODUCT' AND IsActive = 1;

                        SELECT StatusID INTO v_StatusID
                        FROM PromotionStatuses WHERE Code = 'PENDING' AND IsActive = 1;

                        START TRANSACTION;

                        INSERT INTO Promotions (
                            VendorID, Name, Description, PromoCode,
                            DiscountTypeID, DiscountValue, MaxDiscountAmount, MinOrderAmount,
                            ScopeTypeID, TargetProductID, TargetCategoryID,
                            UsageLimitTotal, UsageLimitPerUser, UsageCount,
                            StartDate, EndDate, StatusID, IsActive
                        ) VALUES (
                            v_VendorProfileID, v_Name, v_Description, v_PromoCode,
                            v_DiscountTypeID, v_DiscountValue, v_MaxDiscountAmount, v_MinOrderAmount,
                            v_ScopeTypeID, v_ProductID, NULL,
                            v_UsageLimitTotal, IFNULL(v_UsageLimitPerUser, 1), 0,
                            v_StartDate, v_EndDate, v_StatusID, b'1'
                        );

                        SET v_PromotionID = LAST_INSERT_ID();

                        COMMIT;

                        SET v_Success = TRUE;
                        SET v_Message = 'Promotion créée avec succès';
                    END IF;
                END IF;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_CreatePromotionForCategory(
    IN v_UserPublicID VARCHAR(36),
    IN v_CategoryID INT,
    IN v_Name VARCHAR(150),
    IN v_Description VARCHAR(500),
    IN v_PromoCode VARCHAR(50),
    IN v_DiscountTypeCode VARCHAR(30),
    IN v_DiscountValue DECIMAL(10,2),
    IN v_MaxDiscountAmount DECIMAL(10,2),
    IN v_MinOrderAmount DECIMAL(10,2),
    IN v_UsageLimitTotal INT UNSIGNED,
    IN v_UsageLimitPerUser INT UNSIGNED,
    IN v_StartDate DATETIME,
    IN v_EndDate DATETIME,
    OUT v_PromotionID INT UNSIGNED,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT;
    DECLARE v_CategoryExists INT;
    DECLARE v_DiscountTypeID INT UNSIGNED;
    DECLARE v_ScopeTypeID INT UNSIGNED;
    DECLARE v_StatusID INT UNSIGNED;
    DECLARE v_DuplicateCode INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_CreatePromotionForCategory',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('UserPublicID', v_UserPublicID, 'CategoryID', v_CategoryID, 'PromoCode', v_PromoCode)
        );

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la création de la promotion.';
        SET v_PromotionID = NULL;
    END;

    SET v_Success = FALSE;
    SET v_Message = '';
    SET v_PromotionID = NULL;

    -- Résolution utilisateur (admin)
    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        -- Vérification existence de la catégorie
        SELECT COUNT(*) INTO v_CategoryExists FROM Categories WHERE CategoryID = v_CategoryID;

        IF v_CategoryExists = 0 THEN
            SET v_Message = 'Catégorie introuvable';
        ELSE
            -- Résolution du DiscountTypeID
            SELECT DiscountTypeID INTO v_DiscountTypeID
            FROM PromotionDiscountTypes
            WHERE Code = v_DiscountTypeCode AND IsActive = 1;

            IF v_DiscountTypeID IS NULL THEN
                SET v_Message = 'Type de réduction invalide';
            ELSEIF v_DiscountValue IS NULL OR v_DiscountValue <= 0 THEN
                SET v_Message = 'La valeur de la réduction doit être supérieure à 0';
            ELSEIF v_DiscountTypeCode = 'PERCENTAGE' AND v_DiscountValue > 100 THEN
                SET v_Message = 'Le pourcentage de réduction ne peut pas dépasser 100';
            ELSEIF v_MinOrderAmount IS NOT NULL AND v_MinOrderAmount < 0 THEN
                SET v_Message = 'Le montant minimum de commande doit être supérieur ou égal à 0';
            ELSEIF v_StartDate IS NULL OR v_EndDate IS NULL THEN
                SET v_Message = 'Les dates de début et de fin sont obligatoires';
            ELSEIF v_EndDate <= v_StartDate THEN
                SET v_Message = 'La date de fin doit être postérieure à la date de début';
            ELSE
                -- Unicité du PromoCode (si fourni)
                IF v_PromoCode IS NOT NULL THEN
                    SELECT COUNT(*) INTO v_DuplicateCode
                    FROM Promotions
                    WHERE PromoCode = v_PromoCode AND DeletedAt IS NULL;
                ELSE
                    SET v_DuplicateCode = 0;
                END IF;

                IF v_DuplicateCode > 0 THEN
                    SET v_Message = 'Ce code promo est déjà utilisé';
                ELSE
                    SELECT ScopeTypeID INTO v_ScopeTypeID
                    FROM PromotionScopeTypes WHERE Code = 'CATEGORY' AND IsActive = 1;

                    SELECT StatusID INTO v_StatusID
                    FROM PromotionStatuses WHERE Code = 'VALIDATED' AND IsActive = 1;

                    START TRANSACTION;

                    INSERT INTO Promotions (
                        VendorID, Name, Description, PromoCode,
                        DiscountTypeID, DiscountValue, MaxDiscountAmount, MinOrderAmount,
                        ScopeTypeID, TargetProductID, TargetCategoryID,
                        UsageLimitTotal, UsageLimitPerUser, UsageCount,
                        StartDate, EndDate, StatusID, IsActive
                    ) VALUES (
                        NULL, v_Name, v_Description, v_PromoCode,
                        v_DiscountTypeID, v_DiscountValue, v_MaxDiscountAmount, v_MinOrderAmount,
                        v_ScopeTypeID, NULL, v_CategoryID,
                        v_UsageLimitTotal, IFNULL(v_UsageLimitPerUser, 1), 0,
                        v_StartDate, v_EndDate, v_StatusID, b'1'
                    );

                    SET v_PromotionID = LAST_INSERT_ID();

                    COMMIT;

                    SET v_Success = TRUE;
                    SET v_Message = 'Promotion créée avec succès';
                END IF;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;


DELIMITER $$
CREATE PROCEDURE SP_UpdatePromotion(
    IN v_UserPublicID VARCHAR(36),
    IN v_PromotionID INT UNSIGNED,
    IN v_Name VARCHAR(150),
    IN v_Description VARCHAR(500),
    IN v_PromoCode VARCHAR(50),
    IN v_DiscountTypeCode VARCHAR(30),
    IN v_DiscountValue DECIMAL(10,2),
    IN v_MaxDiscountAmount DECIMAL(10,2),
    IN v_MinOrderAmount DECIMAL(10,2),
    IN v_UsageLimitTotal INT UNSIGNED,
    IN v_UsageLimitPerUser INT UNSIGNED,
    IN v_StartDate DATETIME,
    IN v_EndDate DATETIME,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT;
    DECLARE v_UserRoleCode VARCHAR(30);
    DECLARE v_VendorProfileID INT;
    DECLARE v_PromoVendorID INT;
    DECLARE v_ScopeCode VARCHAR(30);
    DECLARE v_DiscountTypeID INT UNSIGNED;
    DECLARE v_DuplicateCode INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_UpdatePromotion',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('UserPublicID', v_UserPublicID, 'PromotionID', v_PromotionID, 'PromoCode', v_PromoCode)
        );

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la mise à jour de la promotion.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    -- Résolution utilisateur + rôle (via UserRoles -> Roles)
    SELECT u.UserID, r.Code
    INTO v_UserID, v_UserRoleCode
    FROM Users u
    JOIN UserRoles ur ON ur.UserID = u.UserID
    JOIN Roles r ON r.RoleID = ur.RoleID
    WHERE u.PublicID = v_UserPublicID
    LIMIT 1;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        -- Résolution de la promotion + son scope
        SELECT p.VendorID, st.Code
        INTO v_PromoVendorID, v_ScopeCode
        FROM Promotions p
        JOIN PromotionScopeTypes st ON st.ScopeTypeID = p.ScopeTypeID
        WHERE p.PromotionID = v_PromotionID AND p.DeletedAt IS NULL;

        IF v_ScopeCode IS NULL THEN
            SET v_Message = 'Promotion introuvable';
        ELSEIF v_ScopeCode = 'PRODUCT' THEN
            IF v_UserRoleCode <> 'VENDOR' THEN
                SET v_Message = 'Accès refusé : réservé au vendeur propriétaire';
            ELSE
                SELECT VendorProfileID INTO v_VendorProfileID
                FROM VendorProfiles WHERE UserID = v_UserID;

                IF v_VendorProfileID IS NULL OR v_VendorProfileID <> v_PromoVendorID THEN
                    SET v_Message = 'Accès refusé : vous n''êtes pas propriétaire de cette promotion';
                END IF;
            END IF;
        ELSEIF v_ScopeCode = 'CATEGORY' THEN
            IF v_UserRoleCode <> 'ADMIN' THEN
                SET v_Message = 'Accès refusé : réservé aux administrateurs';
            END IF;
        ELSE
            SET v_Message = 'Portée de promotion non gérée';
        END IF;

        IF v_Message = '' THEN
            -- Validations métier (mêmes règles qu'à la création)
            SELECT DiscountTypeID INTO v_DiscountTypeID
            FROM PromotionDiscountTypes
            WHERE Code = v_DiscountTypeCode AND IsActive = 1;

            IF v_DiscountTypeID IS NULL THEN
                SET v_Message = 'Type de réduction invalide';
            ELSEIF v_DiscountValue IS NULL OR v_DiscountValue <= 0 THEN
                SET v_Message = 'La valeur de la réduction doit être supérieure à 0';
            ELSEIF v_DiscountTypeCode = 'PERCENTAGE' AND v_DiscountValue > 100 THEN
                SET v_Message = 'Le pourcentage de réduction ne peut pas dépasser 100';
            ELSEIF v_MinOrderAmount IS NOT NULL AND v_MinOrderAmount < 0 THEN
                SET v_Message = 'Le montant minimum de commande doit être supérieur ou égal à 0';
            ELSEIF v_StartDate IS NULL OR v_EndDate IS NULL THEN
                SET v_Message = 'Les dates de début et de fin sont obligatoires';
            ELSEIF v_EndDate <= v_StartDate THEN
                SET v_Message = 'La date de fin doit être postérieure à la date de début';
            ELSE
                IF v_PromoCode IS NOT NULL THEN
                    SELECT COUNT(*) INTO v_DuplicateCode
                    FROM Promotions
                    WHERE PromoCode = v_PromoCode
                      AND DeletedAt IS NULL
                      AND PromotionID <> v_PromotionID;
                ELSE
                    SET v_DuplicateCode = 0;
                END IF;

                IF v_DuplicateCode > 0 THEN
                    SET v_Message = 'Ce code promo est déjà utilisé';
                ELSE
                    START TRANSACTION;

                    UPDATE Promotions
                    SET Name              = v_Name,
                        Description       = v_Description,
                        PromoCode         = v_PromoCode,
                        DiscountTypeID    = v_DiscountTypeID,
                        DiscountValue     = v_DiscountValue,
                        MaxDiscountAmount = v_MaxDiscountAmount,
                        MinOrderAmount    = v_MinOrderAmount,
                        UsageLimitTotal   = v_UsageLimitTotal,
                        UsageLimitPerUser = IFNULL(v_UsageLimitPerUser, 1),
                        StartDate         = v_StartDate,
                        EndDate           = v_EndDate
                    WHERE PromotionID = v_PromotionID;

                    COMMIT;

                    SET v_Success = TRUE;
                    SET v_Message = 'Promotion mise à jour avec succès';
                END IF;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_SoftDeletePromotion(
    IN v_UserPublicID VARCHAR(36),
    IN v_PromotionID INT UNSIGNED,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT;
    DECLARE v_VendorProfileID INT;
    DECLARE v_OwnerVendorID INT;
    DECLARE v_AlreadyDeleted DATETIME;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_SoftDeletePromotion',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('UserPublicID', v_UserPublicID, 'PromotionID', v_PromotionID)
        );

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la suppression de la promotion.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    -- Résolution utilisateur
    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = v_UserPublicID;
    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        -- Résolution profil vendeur
        SELECT VendorProfileID INTO v_VendorProfileID
        FROM VendorProfiles WHERE UserID = v_UserID;

        IF v_VendorProfileID IS NULL THEN
            SET v_Message = 'Profil vendeur introuvable pour cet utilisateur';
        ELSE
            -- Résolution de la promotion + vérification de propriété + statut suppression
            SELECT VendorID, DeletedAt
            INTO v_OwnerVendorID, v_AlreadyDeleted
            FROM Promotions
            WHERE PromotionID = v_PromotionID;

            IF v_OwnerVendorID IS NULL THEN
                SET v_Message = 'Promotion introuvable';
            ELSEIF v_AlreadyDeleted IS NOT NULL THEN
                SET v_Message = 'Cette promotion est déjà supprimée';
            ELSEIF v_OwnerVendorID <> v_VendorProfileID THEN
                SET v_Message = 'Accès refusé : vous n''êtes pas propriétaire de cette promotion';
            ELSE
                START TRANSACTION;

                UPDATE Promotions
                SET DeletedAt = NOW(),
                    IsActive = b'0'
                WHERE PromotionID = v_PromotionID;

                COMMIT;

                SET v_Success = TRUE;
                SET v_Message = 'Promotion supprimée avec succès';
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;
ALTER TABLE SPErrorLogs
CHANGE COLUMN `SQLState` ErrorSQLState VARCHAR(10);
DELIMITER $$
CREATE PROCEDURE SP_DeactivatePromotion(
    IN v_UserPublicID VARCHAR(36),
    IN v_PromotionID INT UNSIGNED,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT;
    DECLARE v_AdminID INT;
    DECLARE v_VendorProfileID INT;
    DECLARE v_OwnerVendorID INT;
    DECLARE v_ScopeTypeCode VARCHAR(30);
    DECLARE v_DeletedAt DATETIME;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO SPErrorLogs
        (
            ProcedureName,
            ErrorSQLState,
            ErrorNumber,
            ErrorMessage,
            ContextData
        )
        VALUES
        (
            'SP_DeactivatePromotion',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'UserPublicID', v_UserPublicID,
                'PromotionID', v_PromotionID
            )
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la désactivation de la promotion.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    -- Get user
    SELECT UserID
    INTO v_UserID
    FROM Users
    WHERE PublicID = v_UserPublicID;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        -- Check if user is Admin
        SELECT AdminProfileID INTO v_AdminID
        FROM AdminProfiles
        WHERE UserID = v_UserID;

        -- Resolve target promotion (vendor owner + scope)
        SELECT p.VendorID, st.Code, p.DeletedAt
        INTO v_OwnerVendorID, v_ScopeTypeCode, v_DeletedAt
        FROM Promotions p
        INNER JOIN PromotionScopeTypes st ON st.ScopeTypeID = p.ScopeTypeID
        WHERE p.PromotionID = v_PromotionID;

        IF v_OwnerVendorID IS NULL THEN
            SET v_Message = 'Promotion introuvable';
        ELSEIF v_DeletedAt IS NOT NULL THEN
            SET v_Message = 'Cette promotion a été supprimée';
        ELSEIF v_ScopeTypeCode = 'CATEGORY' AND v_AdminID IS NULL THEN
            -- Promotions de catégorie : réservées à l'admin
            SET v_Message = 'Accès refusé : seul un administrateur peut modifier une promotion de catégorie';
        ELSEIF v_ScopeTypeCode <> 'CATEGORY' AND v_AdminID IS NULL THEN
            -- Promotions produit/catalogue : admin OU vendeur propriétaire
            SELECT VendorProfileID INTO v_VendorProfileID
            FROM VendorProfiles WHERE UserID = v_UserID;

            IF v_VendorProfileID IS NULL OR v_VendorProfileID <> v_OwnerVendorID THEN
                SET v_Message = 'Accès refusé : vous n''êtes pas propriétaire de cette promotion';
            ELSE
                START TRANSACTION;
                UPDATE Promotions
                SET IsActive = b'0'
                WHERE PromotionID = v_PromotionID;
                COMMIT;

                SET v_Success = TRUE;
                SET v_Message = 'Promotion désactivée avec succès';
            END IF;
        ELSE
            -- Admin : autorisé dans tous les cas
            START TRANSACTION;
            UPDATE Promotions
            SET IsActive = b'0'
            WHERE PromotionID = v_PromotionID;
            COMMIT;

            SET v_Success = TRUE;
            SET v_Message = 'Promotion désactivée avec succès';
        END IF;
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE SP_GetPromotionByID(
    IN v_UserPublicID VARCHAR(36),
    IN v_PromotionID INT UNSIGNED,
    OUT v_Success BOOLEAN,
    OUT v_Message VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT;
    DECLARE v_AdminID INT;
    DECLARE v_VendorProfileID INT;
    DECLARE v_OwnerVendorID INT;
    DECLARE v_ScopeTypeCode VARCHAR(30);
    DECLARE v_DeletedAt DATETIME;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs
        (
            ProcedureName,
            ErrorSQLState,
            ErrorNumber,
            ErrorMessage,
            ContextData
        )
        VALUES
        (
            'SP_GetPromotionByID',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'UserPublicID', v_UserPublicID,
                'PromotionID', v_PromotionID
            )
        );

        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération de la promotion.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    -- Get user
    SELECT UserID
    INTO v_UserID
    FROM Users
    WHERE PublicID = v_UserPublicID;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable';
    ELSE
        -- Check if user is Admin
        SELECT AdminProfileID INTO v_AdminID
        FROM AdminProfiles
        WHERE UserID = v_UserID;

        -- Resolve target promotion (vendor owner + scope), soft-deleted excluded
        SELECT p.VendorID, st.Code, p.DeletedAt
        INTO v_OwnerVendorID, v_ScopeTypeCode, v_DeletedAt
        FROM Promotions p
        INNER JOIN PromotionScopeTypes st ON st.ScopeTypeID = p.ScopeTypeID
        WHERE p.PromotionID = v_PromotionID;

        IF v_OwnerVendorID IS NULL THEN
            SET v_Message = 'Promotion introuvable';
        ELSEIF v_DeletedAt IS NOT NULL THEN
            SET v_Message = 'Promotion introuvable';
        ELSEIF v_ScopeTypeCode = 'CATEGORY' AND v_AdminID IS NULL THEN
            -- Promotions de catégorie : consultables uniquement par l'admin
            SET v_Message = 'Accès refusé : seul un administrateur peut consulter une promotion de catégorie';
        ELSEIF v_ScopeTypeCode <> 'CATEGORY' AND v_AdminID IS NULL THEN
            -- Promotions produit/catalogue : admin OU vendeur propriétaire
            SELECT VendorProfileID INTO v_VendorProfileID
            FROM VendorProfiles WHERE UserID = v_UserID;

            IF v_VendorProfileID IS NULL OR v_VendorProfileID <> v_OwnerVendorID THEN
                SET v_Message = 'Accès refusé : vous n''êtes pas propriétaire de cette promotion';
            ELSE
                SET v_Success = TRUE;
                SET v_Message = 'OK';

                SELECT
                    p.PromotionID, p.VendorID, p.Name, p.Description, p.PromoCode,
                    dt.Code AS DiscountTypeCode, dt.Label AS DiscountTypeLabel,
                    p.DiscountValue, p.MaxDiscountAmount, p.MinOrderAmount,
                    st.Code AS ScopeTypeCode, st.Label AS ScopeTypeLabel,
                    p.TargetProductID, p.TargetCategoryID,
                    p.UsageLimitTotal, p.UsageLimitPerUser, p.UsageCount,
                    p.StartDate, p.EndDate,
                    ps.Code AS StatusCode, ps.Label AS StatusLabel,
                    CAST(p.IsActive AS UNSIGNED) AS IsActive,
                    p.CreatedAt, p.UpdatedAt
                FROM Promotions p
                INNER JOIN PromotionDiscountTypes dt ON dt.DiscountTypeID = p.DiscountTypeID
                INNER JOIN PromotionScopeTypes st ON st.ScopeTypeID = p.ScopeTypeID
                INNER JOIN PromotionStatuses ps ON ps.StatusID = p.StatusID
                WHERE p.PromotionID = v_PromotionID;
            END IF;
        ELSE
            -- Admin : autorisé dans tous les cas
            SET v_Success = TRUE;
            SET v_Message = 'OK';

            SELECT
                p.PromotionID, p.VendorID, p.Name, p.Description, p.PromoCode,
                dt.Code AS DiscountTypeCode, dt.Label AS DiscountTypeLabel,
                p.DiscountValue, p.MaxDiscountAmount, p.MinOrderAmount,
                st.Code AS ScopeTypeCode, st.Label AS ScopeTypeLabel,
                p.TargetProductID, p.TargetCategoryID,
                p.UsageLimitTotal, p.UsageLimitPerUser, p.UsageCount,
                p.StartDate, p.EndDate,
                ps.Code AS StatusCode, ps.Label AS StatusLabel,
                CAST(p.IsActive AS UNSIGNED) AS IsActive,
                p.CreatedAt, p.UpdatedAt
            FROM Promotions p
            INNER JOIN PromotionDiscountTypes dt ON dt.DiscountTypeID = p.DiscountTypeID
            INNER JOIN PromotionScopeTypes st ON st.ScopeTypeID = p.ScopeTypeID
            INNER JOIN PromotionStatuses ps ON ps.StatusID = p.StatusID
            WHERE p.PromotionID = v_PromotionID;
        END IF;
    END IF;
END$$

DELIMITER ;