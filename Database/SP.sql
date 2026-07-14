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
         u.UserID as userId,
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


--New Today : 12/07/2025

DELIMITER $$

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

DELIMITER $$

DROP PROCEDURE IF EXISTS SP_CreateVendorUser$$

CREATE PROCEDURE SP_CreateVendorUser
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
    IN p_TTL INT,

    -- Store information
    IN p_StoreName VARCHAR(150),
    IN p_Description TEXT
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

    INSERT INTO VendorProfiles
    (
        UserID,
        StoreName,
        Description,
        LogoURL,
        BannerURL,
        Rating,
        ReviewCount,
        IdentityVerified,
        BusinessVerified,
        BankVerified,
        VerificationStatus,
        IsApproved,
        IsSuspended,
        SuspendedAt,
        ApprovedAt
    )
    VALUES
    (
        v_ID,
        p_StoreName,
        p_Description,
        NULL,
        NULL,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        NULL,
        NULL
    );

    INSERT INTO UserRoles
    (
        UserID,
        RoleID,
        AssignedBy
    )
    VALUES
    (
        v_ID,
        2,
        NULL
    );

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

    SELECT
        v_ID AS UserID,
        v_PublicID AS PublicID;
END$$
DELIMITER $$

CREATE PROCEDURE `SP_GetVendorsCount`(
    IN p_Search VARCHAR(255),
    IN p_VerificationStatus TINYINT,
    IN p_IsSuspended TINYINT
)
BEGIN
    SELECT COUNT(*) AS TotalCount
    FROM VendorProfiles vp
    JOIN Users u ON u.UserID = vp.UserID
    WHERE (p_Search IS NULL OR vp.StoreName LIKE CONCAT('%', p_Search, '%') OR u.Email LIKE CONCAT('%', p_Search, '%'))
      AND (p_VerificationStatus IS NULL OR vp.VerificationStatus = p_VerificationStatus)
      AND (p_IsSuspended IS NULL OR vp.IsSuspended = p_IsSuspended)
      AND u.IsDeleted = 0;
END$$

DELIMITER ;
DELIMITER ;

--Not SP but ALTER TABLE VendorProfiles to add new columns for verification and suspension information
ALTER TABLE VendorProfiles ADD COLUMN VerifiedBy INT NULL;       -- FK Users (admin who verified)
ALTER TABLE VendorProfiles ADD COLUMN VerificationNotes NVARCHAR(500) NULL;
ALTER TABLE VendorProfiles ADD COLUMN RejectionNotes NVARCHAR(500) NULL;
ALTER TABLE VendorProfiles ADD COLUMN SuspendedBy INT NULL;          -- FK Users (admin who suspended)
ALTER TABLE VendorProfiles ADD COLUMN SuspensionNotes NVARCHAR(500) NULL;
DELIMITER $$
DROP PROCEDURE IF EXISTS SP_GetVendorsList$$
CREATE PROCEDURE SP_GetVendorsList
(
    IN p_Search VARCHAR(255),
    IN p_VerificationStatus TINYINT,
    IN p_IsSuspended TINYINT,
    IN p_PageNumber INT,
    IN p_PageSize INT
)
BEGIN
    DECLARE v_Offset INT;

    SET p_PageNumber = IFNULL(p_PageNumber, 1);
    SET p_PageSize = IFNULL(p_PageSize, 10);

    SET v_Offset = GREATEST((p_PageNumber - 1) * p_PageSize, 0);

    SELECT
        vp.VendorProfileID,
        vp.UserID,
        vp.StoreName,
        vp.LogoURL,

        u.FirstName,
        u.LastName,
        u.Email,
        u.PhoneNumber,
        u.LastLoginAt,
        u.IsActive,

        CASE vp.VerificationStatus
            WHEN 0 THEN 'Pending'
            WHEN 1 THEN 'Verified'
            WHEN 2 THEN 'Rejected'
            ELSE 'Unknown'
        END AS VerificationStatus,

        vp.IdentityVerified,
        vp.BusinessVerified,
        vp.BankVerified,

        vp.IsApproved,
        vp.IsSuspended,
        vp.SuspendedAt,

        vp.Rating,
        vp.ReviewCount,
        vp.CreatedAt,

        (
            SELECT COUNT(*)
            FROM Products p
            WHERE p.VendorID = vp.UserID
        ) AS TotalProducts,

        (
            SELECT COUNT(*)
            FROM Products p
            WHERE p.VendorID = vp.UserID
              AND p.Status = 'Accepted'
              AND p.IsActive = 1
        ) AS ActiveProducts,

        (
            SELECT COUNT(*)
            FROM Products p
            WHERE p.VendorID = vp.UserID
              AND p.Status IN ('Draft','Validated')
        ) AS PendingProducts,

        (
            SELECT COUNT(DISTINCT oi.OrderID)
            FROM OrderItems oi
            WHERE oi.VendorProfileID = vp.VendorProfileID
        ) AS TotalOrders,

        (
            SELECT COALESCE(SUM(oi.Total), 0)
            FROM OrderItems oi
            WHERE oi.VendorProfileID = vp.VendorProfileID
        ) AS TotalRevenue,

        COALESCE(ba.WithdrawableBalance, 0) AS WithdrawableBalance

    FROM VendorProfiles vp
    INNER JOIN Users u
        ON u.UserID = vp.UserID

    LEFT JOIN BankAccounts ba
        ON ba.VendorProfileID = vp.VendorProfileID

    WHERE
        u.IsDeleted = 0
        AND (
            p_Search IS NULL
            OR p_Search = ''
            OR vp.StoreName LIKE CONCAT('%', p_Search, '%')
            OR u.FirstName LIKE CONCAT('%', p_Search, '%')
            OR u.LastName LIKE CONCAT('%', p_Search, '%')
            OR u.Email LIKE CONCAT('%', p_Search, '%')
            OR u.PhoneNumber LIKE CONCAT('%', p_Search, '%')
        )
        AND (
            p_VerificationStatus IS NULL
            OR vp.VerificationStatus = p_VerificationStatus
        )
        AND (
            p_IsSuspended IS NULL
            OR vp.IsSuspended = p_IsSuspended
        )

    ORDER BY vp.CreatedAt DESC

    LIMIT p_PageSize OFFSET v_Offset;

END$$

DELIMITER ;

DELIMITER $$
DROP PROCEDURE IF EXISTS SP_ApproveVendor$$
CREATE PROCEDURE SP_ApproveVendor
(
    IN p_VendorProfileID INT,
    IN p_VerifiedBy INT,
    IN p_VerificationNotes VARCHAR(500)
)
BEGIN
   /* DECLARE v_IdentityVerified TINYINT(1);
    DECLARE v_BusinessVerified TINYINT(1);
    DECLARE v_BankVerified TINYINT(1);*/

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

   /* SELECT IdentityVerified, BusinessVerified, BankVerified
    INTO v_IdentityVerified, v_BusinessVerified, v_BankVerified
    FROM VendorProfiles
    WHERE VendorProfileID = p_VendorProfileID
    FOR UPDATE;

    IF v_IdentityVerified = 0 OR v_BusinessVerified = 0 OR v_BankVerified = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot approve vendor: identity, business, and bank must all be verified first.';
    END IF;*/

    UPDATE VendorProfiles
    SET
        VerificationStatus = 1,          -- Verified
        IsApproved         = 1,
        ApprovedAt         = UTC_TIMESTAMP(),
        VerifiedBy         = p_VerifiedBy,
        VerificationNotes  = p_VerificationNotes,
        RejectionNotes     = NULL,
        UpdatedAt          = UTC_TIMESTAMP()
    WHERE VendorProfileID = p_VendorProfileID;

    COMMIT;

    SELECT
        VendorProfileID,
        VerificationStatus,
        IsApproved,
        ApprovedAt,
        VerifiedBy,
        VerificationNotes
    FROM VendorProfiles
    WHERE VendorProfileID = p_VendorProfileID;
END$$
DELIMITER ;
DELIMITER $$
DROP PROCEDURE IF EXISTS SP_RejectVendor$$
CREATE PROCEDURE SP_RejectVendor
(
    IN p_VendorProfileID INT,
    IN p_VerifiedBy INT,
    IN p_RejectionNotes VARCHAR(500)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE VendorProfiles
    SET
        VerificationStatus = 2,          -- Rejected
        IsApproved         = 0,
        VerifiedBy         = p_VerifiedBy,
        RejectionNotes     = p_RejectionNotes,
        UpdatedAt          = UTC_TIMESTAMP()
    WHERE VendorProfileID = p_VendorProfileID;

    COMMIT;

    SELECT
        VendorProfileID,
        VerificationStatus,
        IsApproved,
        VerifiedBy,
        RejectionNotes
    FROM VendorProfiles
    WHERE VendorProfileID = p_VendorProfileID;
END$$
DELIMITER ;



--NEw SP FROm 13/07/2025
DELIMITER $$
DROP PROCEDURE IF EXISTS SP_CreateCategory$$
CREATE PROCEDURE SP_CreateCategory
(
    IN p_ParentCategoryID INT,
    IN p_Name             VARCHAR(150),
    IN p_IconURL           VARCHAR(255)
)
BEGIN
    DECLARE v_CategoryID     INT;
    DECLARE v_Slug           VARCHAR(160);
    DECLARE v_NormalizedText VARCHAR(255);
    DECLARE v_ParentExists   INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Build slug from name: lowercase, spaces/underscores -> hyphens, strip non [a-z0-9-]
    SET v_Slug = LOWER(TRIM(p_Name));
    SET v_Slug = REPLACE(v_Slug, ' ', '-');
    SET v_Slug = REPLACE(v_Slug, '_', '-');

    -- Normalized text for search (lowercase, trimmed)
    SET v_NormalizedText = LOWER(TRIM(p_Name));

    -- Insert the category
    INSERT INTO Categories
    (
        ParentCategoryID,
        Name,
        Slug,
        IconURL,
        IsActive,
        DisplayOrder
    )
    VALUES
    (
        p_ParentCategoryID,
        p_Name,
        v_Slug,
        p_IconURL,
        1,
        1
    );

    SET v_CategoryID = LAST_INSERT_ID();

    -- Closure table: self-reference (depth 0)
    INSERT INTO CategoryClosure (AncestorID, DescendantID, Depth)
    VALUES (v_CategoryID, v_CategoryID, 0);

    -- Closure table: inherit all ancestors of the parent, depth + 1
    IF p_ParentCategoryID IS NOT NULL THEN
        INSERT INTO CategoryClosure (AncestorID, DescendantID, Depth)
        SELECT AncestorID, v_CategoryID, Depth + 1
        FROM CategoryClosure
        WHERE DescendantID = p_ParentCategoryID;
    END IF;

    -- Search dictionary entry (SourceType = 1 assumed to mean "Category" - confirm/adjust)
    INSERT INTO SearchDictionary
    (
        DisplayText,
        NormalizedText,
        SourceType,
        SourceID,
        Score,
        SearchHitCount,
        SearchHitCount7d,
        ResultCount,
        IsActive
    )
    VALUES
    (
        p_Name,
        v_NormalizedText,
        1,
        v_CategoryID,
        0.0000,
        0,
        0,
        0,
        1
    );

    COMMIT;

    SELECT
        CategoryID,
        ParentCategoryID,
        Name,
        Slug,
        IconURL,
        IsActive,
        DisplayOrder
    FROM Categories
    WHERE CategoryID = v_CategoryID;
END$$
DELIMITER ;
