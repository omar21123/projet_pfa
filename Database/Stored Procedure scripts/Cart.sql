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

CREATE DEFINER=`root`@`%` PROCEDURE `SP_GetCartInformations`(
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
            ci.CartItemID,
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
            IFNULL(poc.ImagePath, (
                SELECT pr.ResourcesPath FROM ProductResources pr
                WHERE pr.ProductID = p.ProductID AND pr.ResourceRoleID = 2 LIMIT 1
            )) AS ImagePath
        FROM CartItems ci
        INNER JOIN Carts c ON c.CartID = ci.CartID
        INNER JOIN Products p ON p.ProductID = ci.ProductID
        LEFT JOIN Brands b ON b.BrandID = p.BrandID
        LEFT JOIN Models m ON m.ModelID = p.ModelID
        LEFT JOIN ProductOptionsCombiniason poc ON poc.CombinationID = ci.CombinaisonID
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

CREATE DEFINER=`root`@`%` PROCEDURE `SP_UpdateCartItemQuantity`(
    IN  p_UserPublicID VARCHAR(64),
    IN  p_CartItemID   INT,
    IN  p_Quantity     DECIMAL(10,2),
    OUT p_success      TINYINT,
    OUT p_message      VARCHAR(255)
)
BEGIN
    DECLARE v_UserID       INT DEFAULT NULL;
    DECLARE v_CartID        INT DEFAULT NULL;
    DECLARE v_ItemCartID    INT DEFAULT NULL;
    DECLARE v_ProductID     INT DEFAULT NULL;
    DECLARE v_ExistsProd    INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_success = 0;
        SET p_message = 'Erreur lors de la mise à jour du panier.';
    END;

    START TRANSACTION;

    -- Résolution UserPublicID -> UserID
    SELECT UserID INTO v_UserID
    FROM Users
    WHERE PublicID = p_UserPublicID
    LIMIT 1;

    IF v_UserID IS NULL THEN
        ROLLBACK;
        SET p_success = 0;
        SET p_message = 'Utilisateur introuvable.';

    ELSE
        -- Récupère le panier de l'utilisateur
        SELECT CartID INTO v_CartID
        FROM Carts
        WHERE UserID = v_UserID
        LIMIT 1;

        IF v_CartID IS NULL THEN
            ROLLBACK;
            SET p_success = 0;
            SET p_message = 'Panier introuvable.';

        ELSE
            -- Vérifie que la ligne de panier existe ET appartient bien à ce panier
            -- (empêche un utilisateur de modifier la ligne d'un autre panier via un CartItemID arbitraire).
            SELECT CartID, ProductID INTO v_ItemCartID, v_ProductID
            FROM CartItems
            WHERE CartItemID = p_CartItemID
            LIMIT 1;

            IF v_ItemCartID IS NULL THEN
                ROLLBACK;
                SET p_success = 0;
                SET p_message = 'Article introuvable dans le panier.';

            ELSEIF v_ItemCartID != v_CartID THEN
                ROLLBACK;
                SET p_success = 0;
                SET p_message = 'Accès refusé : cet article n''appartient pas à votre panier.';

            ELSE
                -- Le produit doit toujours être actif/disponible pour autoriser la mise à jour
                SELECT COUNT(*) INTO v_ExistsProd
                FROM Products
                WHERE ProductID = v_ProductID
                  AND IsActive = 1
                  AND Status = 2;

                IF v_ExistsProd = 0 THEN
                    ROLLBACK;
                    SET p_success = 0;
                    SET p_message = 'Produit introuvable ou non disponible.';

                ELSEIF p_Quantity IS NULL OR p_Quantity <= 0 THEN
                    -- Quantité nulle ou négative -> on retire la ligne du panier
                    -- (comportement standard e-commerce : mettre à 0 = supprimer l'article).
                    DELETE FROM CartItems
                    WHERE CartItemID = p_CartItemID;

                    UPDATE Carts SET UpdatedAt = NOW() WHERE CartID = v_CartID;

                    COMMIT;
                    SET p_success = 1;
                    SET p_message = 'Article retiré du panier.';

                ELSE
                    UPDATE CartItems
                    SET Quantity = p_Quantity
                    WHERE CartItemID = p_CartItemID;

                    UPDATE Carts SET UpdatedAt = NOW() WHERE CartID = v_CartID;

                    COMMIT;
                    SET p_success = 1;
                    SET p_message = 'Quantité mise à jour.';
                END IF;
            END IF;
        END IF;
    END IF;
END
$$

DELIMITER ;
DROP PROCEDURE IF EXISTS SP_ClearCart;

DELIMITER $$

CREATE PROCEDURE SP_ClearCart (
    IN  v_PublicID   VARCHAR(64),
    OUT v_Success    BOOLEAN,
    OUT v_Message    VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_UserID INT DEFAULT NULL;
    DECLARE v_CartID INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_ClearCart',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('PublicID', v_PublicID)
        );

        ROLLBACK;
        SET v_Success = FALSE;
        SET v_Message = 'Une erreur est survenue lors du vidage du panier.';
    END;

    SET v_Success = FALSE;
    SET v_Message = '';

    -- 1) Resolve current user
    SELECT UserID INTO v_UserID
    FROM Users
    WHERE PublicID = v_PublicID
    LIMIT 1;

    IF v_UserID IS NULL THEN
        SET v_Message = 'Utilisateur introuvable.';
        LEAVE main_block;
    END IF;

    -- 2) Resolve cart
    SELECT CartID INTO v_CartID
    FROM Carts
    WHERE UserID = v_UserID
    LIMIT 1;

    IF v_CartID IS NULL THEN
        SET v_Message = 'Panier introuvable pour cet utilisateur.';
        LEAVE main_block;
    END IF;

    START TRANSACTION;

    -- 3) Clear cart items
    DELETE FROM CartItems
    WHERE CartID = v_CartID;

    COMMIT;

    SET v_Success = TRUE;
    SET v_Message = 'Panier vidé avec succès.';
END main_block $$

DELIMITER ;

DROP PROCEDURE IF EXISTS SP_AddCartItem;

DELIMITER $$

CREATE PROCEDURE SP_AddCartItem (
    IN  p_UserPublicID  VARCHAR(64),
    IN  p_ProductID     INT,
    IN  p_CompositionID INT,
    IN  p_Quantity      DECIMAL(10,2),
    IN  p_UnitPrice     DECIMAL(12,2),
    OUT p_success       TINYINT,
    OUT p_message       VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_UserID     INT DEFAULT NULL;
    DECLARE v_CartID     INT DEFAULT NULL;
    DECLARE v_ExistsProd INT DEFAULT 0;
    DECLARE v_ItemExists INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        -- Rollback FIRST so the log insert below runs outside the
        -- failed transaction and actually survives / commits.
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_AddCartItem',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'UserPublicID', p_UserPublicID,
                'ProductID', p_ProductID,
                'CompositionID', p_CompositionID,
                'Quantity', p_Quantity,
                'UnitPrice', p_UnitPrice
            )
        );

        SET p_success = 0;
        SET p_message = 'Erreur lors de l''ajout au panier.';
    END;

    SET p_success = 0;
    SET p_message = '';

    -- Normalisation de la quantité : NULL ou 0 (ou négatif) => 1
    IF p_Quantity IS NULL OR p_Quantity <= 0 THEN
        SET p_Quantity = 1.00;
    END IF;

    -- Résolution UserPublicID -> UserID (même pattern que les autres SP: user identifié par son public id)
    SELECT UserID INTO v_UserID
    FROM Users
    WHERE PublicID = p_UserPublicID
    LIMIT 1;

    IF v_UserID IS NULL THEN
        SET p_message = 'Utilisateur introuvable.';
        LEAVE main_block;
    END IF;

    -- Produit existe et est visible (actif, non bloqué)
    SELECT COUNT(*) INTO v_ExistsProd
    FROM Products
    WHERE ProductID = p_ProductID
      AND IsActive = 1
      AND Status = 2;

    IF v_ExistsProd = 0 THEN
        SET p_message = 'Produit introuvable ou non disponible.';
        LEAVE main_block;
    END IF;

    IF p_CompositionID IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM ProductOptionsCombiniason
        WHERE CombinationID = p_CompositionID
          AND ProductID = p_ProductID
          AND IsActive = 1
    ) THEN
        SET p_message = 'Combinaison introuvable pour ce produit.';
        LEAVE main_block;
    END IF;

    START TRANSACTION;

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
END main_block $$

DELIMITER ;