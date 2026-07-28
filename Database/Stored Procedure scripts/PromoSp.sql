DELIMITER $$

CREATE PROCEDURE SP_GetPromotionDiscountTypes()
BEGIN
    SELECT DiscountTypeID, Code, Label
    FROM PromotionDiscountTypes
    WHERE IsActive = 1
    ORDER BY DiscountTypeID;
END$$

DELIMITER ;

DELIMITER $$
CREATE PROCEDURE SP_GetPromotionScopeTypes()
BEGIN
    SELECT ScopeTypeID, Code, Label FROM PromotionScopeTypes WHERE IsActive = 1 ORDER BY ScopeTypeID;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE SP_GetPromotionStatuses()
BEGIN
    SELECT StatusID, Code, Label FROM PromotionStatuses WHERE IsActive = 1 ORDER BY StatusID;
END$$
DELIMITER ;