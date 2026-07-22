DELIMITER $$

CREATE PROCEDURE SP_GetAllProductsAdmin(
    IN p_Status      INT,
    IN p_VendorID    INT,
    IN p_BrandID     INT,
    IN p_ModelID     INT,
    IN p_Search      VARCHAR(255),
    IN p_IsActive    TINYINT,
    IN p_IsBlocked   TINYINT,
    IN p_DateFrom    DATETIME,
    IN p_DateTo      DATETIME,
    IN p_PageNumber  INT,
    IN p_PageSize    INT,
    OUT p_TotalCount INT,
    OUT p_Success    TINYINT,
    OUT p_Message    VARCHAR(255)
)
BEGIN
    DECLARE v_Offset INT;

    IF p_PageNumber IS NULL OR p_PageNumber < 1 THEN
        SET p_PageNumber = 1;
    END IF;

    IF p_PageSize IS NULL OR p_PageSize < 1 THEN
        SET p_PageSize = 20;
    END IF;

    SET v_Offset = (p_PageNumber - 1) * p_PageSize;

    -- Total count for pagination (assigned to variable, no resultset emitted)
    SELECT COUNT(*) INTO p_TotalCount
    FROM Products p
    INNER JOIN VendorProfiles vp ON vp.VendorProfileID = p.VendorID
    INNER JOIN Users u  ON u.UserID = vp.UserID
    LEFT JOIN Brands b  ON b.BrandID = p.BrandID
    LEFT JOIN Models m  ON m.ModelID = p.ModelID
    INNER JOIN ProductStatus ps ON ps.Id = p.Status
    WHERE (p_Status IS NULL OR p.Status = p_Status)
      AND (p_VendorID IS NULL OR p.VendorID = p_VendorID)
      AND (p_BrandID IS NULL OR p.BrandID = p_BrandID)
      AND (p_ModelID IS NULL OR p.ModelID = p_ModelID)
      AND (p_IsActive IS NULL OR p.IsActive = p_IsActive)
      AND (p_IsBlocked IS NULL OR p.IsBlocked = p_IsBlocked)
      AND (p_DateFrom IS NULL OR p.CreatedAt >= p_DateFrom)
      AND (p_DateTo IS NULL OR p.CreatedAt <= p_DateTo)
      AND (p_Search IS NULL OR p_Search = '' OR p.Name LIKE CONCAT('%', p_Search, '%'));

    -- Actual page of data (single resultset returned to caller)
    SELECT
        p.ProductId,
        p.Name            AS ProductName,
        u.DisplayName      AS FullName,
        b.Name             AS BrandName,
        b.LogoURL          AS BrandLogo,
        m.Name             AS ModelName,
        ps.Libelle         AS Status,
        p.CreatedAt,
        p.RefuseAttempt,
        p.RefuseNotes,
        Rf.DisplayName     AS RefusedBy,
        p.RefuseAt,
        va.DisplayName     AS ValidatorBy,
        p.ValidationNotes,
        p.ValidationDate,
        p.IsActive,
        p.DeletedAt,
        p.IsBlocked,
        p.BlockedDate,
        p.BlockedNotes
    FROM Products p
    INNER JOIN VendorProfiles vp ON vp.VendorProfileID = p.VendorID
    INNER JOIN Users u  ON u.UserID = vp.UserID
    LEFT JOIN Users Rf  ON Rf.UserID = p.RefusedBy
    LEFT JOIN Users va  ON va.UserID = p.ValidatorID
    LEFT JOIN Users bl  ON bl.UserID = p.BlokedBy
    LEFT JOIN Brands b  ON b.BrandID = p.BrandID
    LEFT JOIN Models m  ON m.ModelID = p.ModelID
    INNER JOIN ProductStatus ps ON ps.Id = p.Status
    WHERE (p_Status IS NULL OR p.Status = p_Status)
      AND (p_VendorID IS NULL OR p.VendorID = p_VendorID)
      AND (p_BrandID IS NULL OR p.BrandID = p_BrandID)
      AND (p_ModelID IS NULL OR p.ModelID = p_ModelID)
      AND (p_IsActive IS NULL OR p.IsActive = p_IsActive)
      AND (p_IsBlocked IS NULL OR p.IsBlocked = p_IsBlocked)
      AND (p_DateFrom IS NULL OR p.CreatedAt >= p_DateFrom)
      AND (p_DateTo IS NULL OR p.CreatedAt <= p_DateTo)
      AND (p_Search IS NULL OR p_Search = '' OR p.Name LIKE CONCAT('%', p_Search, '%'))
    ORDER BY ps.Id
    LIMIT p_PageSize OFFSET v_Offset;

    SET p_Success = 1;
    SET p_Message = 'OK';
END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE SP_GetProductDetails(
    IN  p_ProductID INT,
    OUT p_Success    TINYINT,
    OUT p_Message    VARCHAR(255)
)
BEGIN
    DECLARE v_Exists INT DEFAULT 0;

    SELECT COUNT(*) INTO v_Exists FROM Products WHERE ProductID = p_ProductID;

    IF v_Exists = 0 THEN
        SET p_Success = 0;
        SET p_Message = 'Produit introuvable.';
    ELSE
        -- 1) Details
        SELECT
            p.ProductId,
            p.Name            AS ProductName,
            u.DisplayName     AS FullName,
            b.Name            AS BrandName,
            b.LogoURL         AS BrandLogo,
            m.Name            AS ModelName,
            ps.Libelle        AS Status,
            p.Barcode,
            p.Stock,
            p.CreatedAt,
            p.RefuseAttempt,
            p.RefuseNotes,
            Rf.DisplayName    AS RefusedBy,
            p.RefuseAt,
            va.DisplayName    AS ValidatorBy,
            p.ValidationNotes,
            p.ValidationDate,
            p.IsActive,
            p.DeletedAt,
            p.IsBlocked,
            p.BlockedDate,
            p.BlockedNotes
        FROM Products p
        INNER JOIN VendorProfiles vp ON vp.VendorProfileID = p.VendorID
        INNER JOIN Users u  ON u.UserID = vp.UserID
        LEFT JOIN Users Rf  ON Rf.UserID = p.RefusedBy
        LEFT JOIN Users va  ON va.UserID = p.ValidatorID
        LEFT JOIN Users bl  ON bl.UserID = p.BlokedBy
        LEFT JOIN Brands b  ON b.BrandID = p.BrandID
        LEFT JOIN Models m  ON m.ModelID = p.ModelID
        INNER JOIN ProductStatus ps ON ps.Id = p.Status
        WHERE p.ProductID = p_ProductID;

        -- 2) Tags
        SELECT t.Name
        FROM Products p
        INNER JOIN ProductTags pt ON pt.ProductID = p.ProductID
        INNER JOIN Tags t ON t.TagID = pt.TagID
        WHERE p.ProductID = p_ProductID;

        -- 3) Allowed Payments
        SELECT pm.Name AS PaymentName, pm.Code, pm.IconURL
        FROM Products p
        INNER JOIN ProductAllowedPayements pa ON p.ProductID = pa.ProductID
        INNER JOIN PaymentMethods pm ON pm.PaymentMethodID = pa.PayementMethodID
        WHERE p.ProductID = p_ProductID;

        -- 4) Categories
        SELECT c.Name, c.IconURL, pc.IsPrimary
        FROM Products p
        INNER JOIN ProductCategories pc ON p.ProductID = pc.ProductID
        INNER JOIN Categories c ON c.CategoryID = pc.CategoryID
        WHERE p.ProductID = p_ProductID;

        -- 5) Configs
        SELECT pca.Name AS Attribute, co.OptionValue, co.IsDefaultForAttribute
        FROM Products p
        INNER JOIN ProductDetails d ON p.ProductID = d.ProductID
        INNER JOIN ProductsConfigAttribute pca ON pca.AttributeID = d.ProductsConfigAttributeID
        INNER JOIN ConfigAttributeOptions co ON co.OptionID = d.OptionID
        WHERE p.ProductID = p_ProductID;

        SET p_Success = 1;
        SET p_Message = 'OK';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_ValidateProduct(
    IN  p_ProductID   INT,
    IN  p_ValidatorID INT,
    IN  p_Notes       VARCHAR(1000),
    OUT p_Success     TINYINT,
    OUT p_Message     VARCHAR(255)
)
BEGIN
    DECLARE v_Exists    INT DEFAULT 0;
    DECLARE v_Status    INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_Success = 0;
        SET p_Message = 'Une erreur est survenue lors de la validation du produit.';
    END;

    SELECT COUNT(*), MAX(Status)
    INTO v_Exists, v_Status
    FROM Products
    WHERE ProductID = p_ProductID;

    IF v_Exists = 0 THEN
        SET p_Success = 0;
        SET p_Message = 'Produit introuvable.';
    ELSEIF v_Status = 2 THEN
        SET p_Success = 0;
        SET p_Message = 'Ce produit est déjà validé.';
    ELSE
        START TRANSACTION;

        UPDATE Products
        SET
            ValidatorID      = p_ValidatorID,
            ValidationNotes  = p_Notes,
            Status           = 2,
            ValidationDate   = UTC_TIMESTAMP()
        WHERE ProductID = p_ProductID;

        COMMIT;

        SET p_Success = 1;
        SET p_Message = 'Produit validé avec succès.';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE SP_BlockProduct(
    IN  p_ProductID INT,
    IN  p_BlockedBy INT,
    IN  p_Notes     VARCHAR(1000),
    OUT p_Success   TINYINT,
    OUT p_Message   VARCHAR(255)
)
BEGIN
    DECLARE v_Exists    INT DEFAULT 0;
    DECLARE v_IsBlocked TINYINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_Success = 0;
        SET p_Message = 'Une erreur est survenue lors du blocage du produit.';
    END;

    SELECT COUNT(*), MAX(IsBlocked)
    INTO v_Exists, v_IsBlocked
    FROM Products
    WHERE ProductID = p_ProductID;

    IF v_Exists = 0 THEN
        SET p_Success = 0;
        SET p_Message = 'Produit introuvable.';
    ELSEIF v_IsBlocked = 1 THEN
        SET p_Success = 0;
        SET p_Message = 'Ce produit est déjà bloqué.';
    ELSE
        START TRANSACTION;

        UPDATE Products
        SET
            BlokedBy      = p_BlockedBy,
            BlockedNotes  = p_Notes,
            IsBlocked     = 1,
            Status        = 4,
            BlockedDate   = UTC_TIMESTAMP()
        WHERE ProductID = p_ProductID;

        COMMIT;

        SET p_Success = 1;
        SET p_Message = 'Produit bloqué avec succès.';
    END IF;
END$$

DELIMITER ;
DELIMITER $$
CREATE PROCEDURE SP_RefuseProduct(
    IN  p_ProductID   INT,
    IN  p_RefusedBy   INT,
    IN  p_Notes       VARCHAR(1000),
    OUT p_Success     TINYINT,
    OUT p_Message     VARCHAR(255),
    OUT p_AutoBlocked TINYINT
)
BEGIN
    DECLARE v_Exists        INT DEFAULT 0;
    DECLARE v_Status        INT;
    DECLARE v_RefuseAttempt INT DEFAULT 0;
    DECLARE v_BlockMessage  VARCHAR(1000);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_Success = 0;
        SET p_Message = 'Une erreur est survenue lors du refus du produit.';
        SET p_AutoBlocked = 0;
    END;

    SET p_AutoBlocked = 0;

    SELECT COUNT(*), MAX(Status), MAX(RefuseAttempt)
    INTO v_Exists, v_Status, v_RefuseAttempt
    FROM Products
    WHERE ProductID = p_ProductID;

    IF v_Exists = 0 THEN
        SET p_Success = 0;
        SET p_Message = 'Produit introuvable.';
    ELSEIF v_Status <> 1 THEN
        SET p_Success = 0;
        SET p_Message = 'Ce produit nest pas en brouillon, il ne peut pas être refusé.';
    ELSEIF v_RefuseAttempt <= 3 THEN
        START TRANSACTION;

        UPDATE Products
        SET
            RefuseAttempt = RefuseAttempt + 1,
            RefuseNotes   = p_Notes,
            RefusedBy     = p_RefusedBy,
            Status        = 3,
            RefuseAt      = UTC_TIMESTAMP()
        WHERE ProductID = p_ProductID;

        COMMIT;

        SET p_Success = 1;
        SET p_Message = 'Produit refusé.';
    ELSE
        SET v_BlockMessage = CONCAT(
            'Lutilisateur a atteint 3 refus. Ce produit a été automatiquement bloqué. Dernière note de refus : ',
            p_Notes
        );

        CALL SP_BlockProduct(p_ProductID, p_RefusedBy, v_BlockMessage, @b_success, @b_message);

        SET p_Success     = @b_success;
        SET p_Message     = @b_message;
        SET p_AutoBlocked = 1;
    END IF;
END$$

DELIMITER ;