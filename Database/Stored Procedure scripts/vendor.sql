DELIMITER $$

DROP PROCEDURE IF EXISTS sp_GetVendorProfile $$

CREATE PROCEDURE sp_GetVendorProfile(
    IN  p_ProductID VARCHAR(36),
    OUT v_Success   BOOLEAN,
    OUT v_Message   VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_VendorID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'sp_GetVendorProfile',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('ProductID', p_ProductID)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération du profil vendeur.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    -- Validate input
    IF p_ProductID IS NULL THEN
        SET v_Success = FALSE;
        SET v_Message = 'ProductID est requis.';
        LEAVE main_block;
    END IF;

    -- Step 1: Get VendorID from the product
    SELECT VendorID
    INTO v_VendorID
    FROM Products
    WHERE ProductID = p_ProductID;

    IF v_VendorID IS NULL THEN
        SET v_Success = FALSE;
        SET v_Message = 'Produit introuvable ou aucun vendeur associé.';
        LEAVE main_block;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    -- Step 2: Fetch vendor profile
    SELECT
        VendorProfileID,
        StoreName,
        LogoURL ,
        BannerURL,
        ApprovedAt      AS MemberSince,
        IdentityVerified,
        BusinessVerified,
        IsApproved
    FROM VendorProfiles
    WHERE UserID = v_VendorID;

END main_block $$

DELIMITER ;


DELIMITER $$

DROP PROCEDURE IF EXISTS sp_GetVendorPublicProfile $$

CREATE PROCEDURE sp_GetVendorPublicProfile(
    IN  p_VendorProfileID INT,
    OUT v_Success         BOOLEAN,
    OUT v_Message         VARCHAR(255)
)
main_block: BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;
        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'sp_GetVendorPublicProfile',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('VendorProfileID', p_VendorProfileID)
        );
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors de la récupération du profil public vendeur.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    IF p_VendorProfileID IS NULL THEN
        SET v_Message = 'VendorProfileID est requis.';
        LEAVE main_block;
    END IF;

    SET v_Success = TRUE;
    SET v_Message = 'OK';

    SELECT
        v.StoreName,
        v.LogoURL,
        v.BannerURL,
        CASE
            WHEN v.IsApproved = 1 THEN 'Vendeur certifié'
            ELSE '-'
        END AS Note,
        v.Rating,
        v.ReviewCount,
        v.IdentityVerified,
        v.BusinessVerified,
        v.BankVerified,
        (SELECT fn_GetVendorProfileProgress(v.UserID) )AS Progression,
        v.Description,
        v.ApprovedAt,
        fn_GetVendorProfileProgress(v.UserID) AS ProfileProgress,
        CASE
            WHEN a.AddressID IS NULL THEN 'Adresse non spécifiée'
            ELSE CONCAT(a.City, ', ', a.Region, ', ', a.Country)
        END AS Address,
        (
            SELECT GROUP_CONCAT(c.Name SEPARATOR ', ')
            FROM   ProductCategories pc
            INNER JOIN Categories c ON c.CategoryID = pc.CategoryID
            INNER JOIN Products   p ON p.ProductID  = pc.ProductID
            WHERE  p.VendorID = v.UserID
        ) AS HasProductsInCategories,
        (
            SELECT COUNT(*)
            FROM   Products
            WHERE  VendorID = v.UserID
        ) AS TotalProducts,
        (
            SELECT COUNT(*)
            FROM   Orders o
            INNER JOIN OrderItems     oi ON oi.OrderID         = o.OrderID
            INNER JOIN VendorProfiles vp ON vp.VendorProfileID = oi.VendorProfileID
            WHERE  vp.UserID = v.UserID
              AND  o.OrderStatusID NOT IN (1, 5)
        ) AS TotalVentes
    FROM VendorProfiles v
    LEFT JOIN Addresses a ON a.UserID = v.UserID
    WHERE v.VendorProfileID = p_VendorProfileID
    LIMIT 1;

END main_block $$

DELIMITER ;

