DROP PROCEDURE IF EXISTS SP_RemoveCartItem;

DELIMITER $$

CREATE PROCEDURE SP_RemoveCartItem(
    IN  p_UserPublicID  VARCHAR(64),
    IN  p_ProductID     INT,
    IN  p_CompositionID INT,
    OUT p_success       TINYINT,
    OUT p_message       VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_CartID INT DEFAULT NULL;
    DECLARE v_Rows   INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_success = 0;
        SET p_message = 'Erreur lors de la suppression de l''article du panier.';
    END;

    START TRANSACTION;

    SELECT UserID INTO v_UserID
    FROM Users
    WHERE PublicID = p_UserPublicID
    LIMIT 1;

    IF v_UserID IS NULL THEN
        ROLLBACK;
        SET p_success = 0;
        SET p_message = 'Utilisateur introuvable.';
    ELSE
        SELECT CartID INTO v_CartID FROM Carts WHERE UserID = v_UserID LIMIT 1;

        IF v_CartID IS NULL THEN
            ROLLBACK;
            SET p_success = 0;
            SET p_message = 'Panier introuvable.';
        ELSE
            DELETE FROM CartItems
            WHERE CartID = v_CartID
              AND ProductID = p_ProductID
              AND (
                    (p_CompositionID IS NULL AND CombinaisonID IS NULL)
                 OR (CombinaisonID = p_CompositionID)
              );

            SET v_Rows = ROW_COUNT();

            IF v_Rows = 0 THEN
                ROLLBACK;
                SET p_success = 0;
                SET p_message = 'Article introuvable dans le panier.';
            ELSE
                UPDATE Carts SET UpdatedAt = NOW() WHERE CartID = v_CartID;

                COMMIT;
                SET p_success = 1;
                SET p_message = 'Article supprimé du panier.';
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;


DROP PROCEDURE IF EXISTS SP_GetCartInformations;

DELIMITER $$

CREATE PROCEDURE SP_GetCartInformations(
    IN  p_UserPublicID VARCHAR(64),
    OUT p_success      TINYINT,
    OUT p_message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_success = 0;
        SET p_message = 'Erreur lors de la récupération du panier.';
    END;

    SELECT UserID INTO v_UserID FROM Users WHERE PublicID = p_UserPublicID LIMIT 1;

    IF v_UserID IS NULL THEN
        SET p_success = 0;
        SET p_message = 'Utilisateur introuvable.';
    ELSE
        SELECT
            p.ProductID,
            ci.CombinaisonID AS CombinationID,
            p.Name AS ProductName,
            p.Description AS ProductDescription,
            IFNULL(b.Name, 'No Brand') AS BrandName,
            IFNULL(m.Name, 'No Model') AS ModelName,
            ci.UnitPrice,
            ci.Quantity,
            p.Stock,
            poc.SKU,
            poc.ImagePath
        FROM CartItems ci
        INNER JOIN Carts c ON c.CartID = ci.CartID
        INNER JOIN Products p ON p.ProductID = ci.ProductID
        LEFT JOIN Brands b ON b.BrandID = p.BrandID
        LEFT JOIN Models m ON m.ModelID = p.ModelID
        INNER JOIN ProductOptionsCombiniason poc ON poc.CombinationID = ci.CombinaisonID
        WHERE c.UserID = v_UserID;

        SET p_success = 1;
        SET p_message = 'OK';
    END IF;
END$$

DELIMITER ;



DROP PROCEDURE IF EXISTS SP_GetCartItemPromotion;

DELIMITER $$

CREATE PROCEDURE SP_GetCartItemPromotion(
    IN p_ProductID INT
)
BEGIN
    SELECT
        p.PromotionID,
        p.Name,
        p.Description,
        p.StartDate,
        p.EndDate,
        p.DiscountValue,
        pt.Code,
        pt.Label
    FROM Promotions p
    INNER JOIN PromotionDiscountTypes pt ON pt.DiscountTypeID = p.DiscountTypeID
    WHERE p.IsActive = 1
      AND p.ScopeTypeID = 1
      AND p.StatusID = 2
      AND NOW() BETWEEN p.StartDate AND p.EndDate
      AND p.TargetProductID = p_ProductID;
END$$

DELIMITER ;



DROP PROCEDURE IF EXISTS SP_GetCombinationDetails;

DELIMITER $$

CREATE PROCEDURE SP_GetCombinationDetails(
    IN p_CombinationID INT
)
BEGIN
    SELECT
        pocd.CombinationDetailID,
        c.AttributeID,
        c.Name AS ConfigName,
        o.OptionLabel,
        o.OptionID
    FROM ProductOptionsCombiniasonDetails pocd
    INNER JOIN ConfigAttributeOptions o ON pocd.OptionID = o.OptionID
    INNER JOIN ProductsConfigAttribute c ON c.AttributeID = pocd.ProductsConfigAttributeID
    WHERE pocd.CombinationID = p_CombinationID;
END$$

DELIMITER ;