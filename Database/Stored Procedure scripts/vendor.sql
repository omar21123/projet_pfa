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