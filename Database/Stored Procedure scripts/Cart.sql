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
DELIMITER $$

CREATE DEFINER=`root`@`%` PROCEDURE `SP_AddCartItem`(
    IN  p_UserPublicID  VARCHAR(64),
    IN  p_ProductID     INT,
    IN  p_CompositionID INT,
    IN  p_Quantity      DECIMAL(10,2),
    IN  p_UnitPrice     DECIMAL(12,2),
    OUT p_success       TINYINT,
    OUT p_message       VARCHAR(255)
)
BEGIN
    DECLARE v_UserID     INT DEFAULT NULL;
    DECLARE v_CartID     INT DEFAULT NULL;
    DECLARE v_ExistsProd INT DEFAULT 0;
    DECLARE v_ExistsComb INT DEFAULT 0;
    DECLARE v_ItemExists INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_success = 0;
        SET p_message = 'Erreur lors de l''ajout au panier.';
    END;

    -- Normalisation de la quantité : NULL ou 0 (ou négatif) => 1
    IF p_Quantity IS NULL OR p_Quantity <= 0 THEN
        SET p_Quantity = 1.00;
    END IF;

    START TRANSACTION;

    -- Résolution UserPublicID -> UserID (même pattern que les autres SP: user identifié par son public id)
    SELECT UserID INTO v_UserID
    FROM Users
    WHERE PublicID = p_UserPublicID
    LIMIT 1;

    IF v_UserID IS NULL THEN
        ROLLBACK;
        SET p_success = 0;
        SET p_message = 'Utilisateur introuvable.';
    ELSE
        -- Produit existe et est visible (actif, non bloqué)
        SELECT COUNT(*) INTO v_ExistsProd
        FROM Products
        WHERE ProductID = p_ProductID
          AND IsActive = 1
          AND Status = 2;

        IF v_ExistsProd = 0 THEN
            ROLLBACK;
            SET p_success = 0;
            SET p_message = 'Produit introuvable ou non disponible.';
        ELSEIF p_CompositionID IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM ProductOptionsCombiniason
            WHERE CombinationID = p_CompositionID
              AND ProductID = p_ProductID
              AND IsActive = 1
        ) THEN
            ROLLBACK;
            SET p_success = 0;
            SET p_message = 'Combinaison introuvable pour ce produit.';
        ELSE
            -- Get or create cart (UserID est UNIQUE sur Carts)
            SELECT CartID INTO v_CartID FROM Carts WHERE UserID = v_UserID LIMIT 1;
            IF v_CartID IS NULL THEN
                INSERT INTO Carts (UserID) VALUES (v_UserID);
                SET v_CartID = LAST_INSERT_ID();
            END IF;

            -- Upsert de la ligne de panier : si le produit (+ combinaison) est déjà
            -- dans le panier, on incrémente la quantité (de p_Quantity) au lieu de dupliquer la ligne.
            SELECT COUNT(*) INTO v_ItemExists
            FROM CartItems
            WHERE CartID = v_CartID
              AND ProductID = p_ProductID
              AND (
                    (p_CompositionID IS NULL AND CombinaisonID IS NULL)
                 OR (CombinaisonID = p_CompositionID)
              );

            IF v_ItemExists > 0 THEN
                UPDATE CartItems
                SET Quantity  = Quantity + p_Quantity,
                    UnitPrice = p_UnitPrice
                WHERE CartID = v_CartID
                  AND ProductID = p_ProductID
                  AND (
                        (p_CompositionID IS NULL AND CombinaisonID IS NULL)
                     OR (CombinaisonID = p_CompositionID)
                  );
            ELSE
                INSERT INTO CartItems (CartID, ProductID, CombinaisonID, Quantity, UnitPrice)
                VALUES (v_CartID, p_ProductID, p_CompositionID, p_Quantity, p_UnitPrice);
            END IF;

            UPDATE Carts SET UpdatedAt = NOW() WHERE CartID = v_CartID;

            COMMIT;
            SET p_success = 1;
            SET p_message = 'Produit ajouté au panier.';
        END IF;
    END IF;
END
$$

DELIMITER ;