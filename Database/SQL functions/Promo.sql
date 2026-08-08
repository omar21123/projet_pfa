DROP FUNCTION IF EXISTS FN_HasActivePromotion;
DELIMITER $$

CREATE DEFINER=`root`@`%` FUNCTION FN_HasActivePromotion(
    p_ProductID INT
)
RETURNS TINYINT(1)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_Found TINYINT(1) DEFAULT 0;

    SELECT COUNT(*) > 0 INTO v_Found
    FROM Promotions p
    JOIN PromotionDiscountTypes ty ON ty.DiscountTypeID = p.DiscountTypeID
    WHERE p.ScopeTypeID = 1
      AND p.StatusID = 2
      AND p.IsActive = 1
      AND NOW() BETWEEN p.StartDate AND p.EndDate
      AND p.UsageCount < p.UsageLimitTotal
      AND p.TargetProductID = p_ProductID;

    RETURN v_Found;
END$$

DELIMITER ;