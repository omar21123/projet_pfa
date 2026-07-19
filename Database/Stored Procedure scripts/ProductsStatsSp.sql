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