CREATE PROCEDURE SP_CreateAdminUser
(
    IN p_FirstName VARCHAR(100),
    IN p_LastName VARCHAR(100),
    IN p_BirthDate DATE,
    IN p_Gender TINYINT,
    IN p_Email VARCHAR(255),
    IN p_PhoneNumber VARCHAR(30),
    IN p_CIN VARCHAR(30),
    IN p_EmployeeNumber VARCHAR(30),
    IN p_Position VARCHAR(30),
    IN p_PasswordHash TEXT,
    IN p_HireDate DATETIME,
    IN p_IdentityVerified INT,
    IN p_AvatarURL VARCHAR(500),
    IN p_TokenHash VARCHAR(255),
    IN p_IPAddress VARCHAR(45),
    IN p_TTL INT
)
BEGIN
    DECLARE v_ID INT;
    DECLARE v_PublicID CHAR(36);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SET v_PublicID = UUID();

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
        v_PublicID,
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

    SET v_ID = LAST_INSERT_ID();

    INSERT INTO AdminProfiles
    (
        UserID,
        EmployeeNumber,
        CIN,
        Position,
        Status,
        IdentityVerified,
        HireDate
    )
    VALUES
    (
        v_ID,               -- UserID
        p_EmployeeNumber,   -- EmployeeNumber
        p_CIN,               -- CIN
        p_Position,          -- Position
        1,                    -- Status
        1,                    -- IdentityVerified
        p_HireDate           -- HireDate
    );

    INSERT INTO UserRoles (UserID, RoleID, AssignedBy)
    VALUES (v_ID, 1, NULL);

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
        v_ID,
        NULL,
        p_TokenHash,
        p_IPAddress,
        DATE_ADD(UTC_TIMESTAMP(), INTERVAL p_TTL DAY),
        0,
        NULL,
        NULL
    );

    COMMIT;

    SELECT v_PublicID AS PublicID;
END$$

DELIMITER ;
