DELIMITER $$

DROP PROCEDURE IF EXISTS SP_GetProductDetails $$

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

        -- 6)  AJOUT : Resources (images / vidéos) — schéma confirmé via SP_CreateProductResource
        SELECT
            rt.Name            AS Type,
            pr.ResourceRoleID  AS Role,
            pr.ResourcesPath   AS Path
        FROM Products p
        INNER JOIN ProductResources pr ON pr.ProductID = p.ProductID
        INNER JOIN ResourcesTypes rt   ON rt.ID = pr.ResourcesTypeID
        WHERE p.ProductID = p_ProductID
        ORDER BY pr.ResourceRoleID;

        SET p_Success = 1;
        SET p_Message = 'OK';
    END IF;
END$$

DELIMITER ;