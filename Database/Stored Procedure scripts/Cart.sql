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