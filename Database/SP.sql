DELIMITER $$

CREATE PROCEDURE sp_CreateCustomerUser
(
    IN p_FirstName VARCHAR(100),
    IN p_LastName VARCHAR(100),
    IN p_BirthDate DATE,
    IN p_Gender TINYINT,
    IN p_Email VARCHAR(255),
    IN p_PhoneNumber VARCHAR(30),
    IN p_PasswordHash TEXT,
    IN p_AvatarURL VARCHAR(500),
    IN p_TokenHash VARCHAR(255),
    IN p_IPAddress VARCHAR(45),
    IN p_TTL INT
)
BEGIN
    DECLARE p_ID INT;
    DECLARE p_PublicID CHAR(36);
   
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SET p_PublicID = UUID();
    INSERT INTO Users
    (
        PublicID,
        FirstName,
        LastName,
        DisplayName,
        BirthDate,
        Gender,
        Email,
        PhoneNumber,
        PasswordHash,
        AvatarURL
    )
    VALUES
    (
        p_PublicID,
        p_FirstName,
        p_LastName,
        CONCAT(p_FirstName, ' ', p_LastName),
        p_BirthDate,
        p_Gender,
        p_Email,
        p_PhoneNumber,
        p_PasswordHash,
        p_AvatarURL
    );

    SET p_ID = LAST_INSERT_ID();
    
    INSERT INTO CustomerProfiles
    (
        UserID,
        LoyaltyPoints,
        AcceptMarketingEmails
    )
    VALUES
    (
        p_ID,
        0,
        0
    );
    INSERT INTO UserRoles (UserID, RoleID, AssignedBy)
VALUES (p_ID, 3, null);
    INSERT INTO UserRefreshTokens
    (
        UserID,
        UserDeviceID,
        TokenHash,
        IPAddress,
        ExpiresAt,
        IsRevoked,
        RevokedAt,
        ReplacedByTokenHash
    )
    VALUES
    (
        p_ID,
        NULL,
        p_TokenHash,
        p_IPAddress,
        DATE_ADD(UTC_TIMESTAMP(), INTERVAL p_TTL DAY),
        0,
        NULL,
        NULL
    );

    COMMIT;

    SELECT p_PublicID AS PublicID;

END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE GetLoginInfoByEmail (
    IN p_Email VARCHAR(255)
)
BEGIN
    SELECT 
        u.PublicID,
        u.DisplayName,
        u.PhoneNumber,
        u.PasswordHash,
        u.AvatarURL,
        u.IsActive,
        u.EmailVerified,
        u.PhoneVerified,
        r.Code
    FROM Users u
    INNER JOIN UserRoles ur ON u.UserID = ur.UserID
    INNER JOIN Roles r ON ur.RoleID = r.RoleID
    WHERE u.IsDeleted = 0 
      AND u.Email = p_Email;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE sp_CreateRefreshToken (
    IN p_UserID     INT,
    IN p_TokenHash  VARCHAR(255),
    IN p_IPAddress  VARCHAR(45),
    IN p_TTL        INT
)
BEGIN
    INSERT INTO UserRefreshTokens (
        UserID, UserDeviceID, TokenHash, IPAddress,
        ExpiresAt, IsRevoked, RevokedAt, ReplacedByTokenHash
    ) VALUES (
        p_UserID, NULL, p_TokenHash, p_IPAddress,
        DATE_ADD(UTC_TIMESTAMP(), INTERVAL p_TTL DAY), 0, NULL, NULL
    );
END$$

DELIMITER ;