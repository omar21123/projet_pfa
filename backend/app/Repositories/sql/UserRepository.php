<?php

namespace App\Repositories\sql;

use App\DTOs\Auth\LoginInfoDto;
use App\DTOs\Auth\RegisterDto;
use App\DTOs\Auth\UserDto;
use App\DTOs\Auth\UserStandardInfoDto;
use App\DTOs\Auth\VendorRegisterDto;
use App\Repositories\Interface\UserRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * ⚠️ SQL brut — pas d'Eloquent. Tables et colonnes en PascalCase
 * pour correspondre exactement à ton schéma SQL Server (V2).
 */
class UserRepository implements UserRepositoryInterface
{
    public function createUser(RegisterDto $dto, string $passwordHash): int
    {
        $sql = "
            INSERT INTO Users (
                PublicID, FirstName, LastName, DisplayName, BirthDate, Gender,
                Email, PhoneNumber, PasswordHash, EmailVerified, PhoneVerified,
                IsActive, IsDeleted, CreatedAt, UpdatedAt
            )
            OUTPUT INSERTED.UserID
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 1, 0, ?, ?)
        ";

        $now = now()->format('Y-m-d H:i:s');

        $result = DB::select($sql, [
            (string) Str::uuid(),
            $dto->firstName,
            $dto->lastName,
            $dto->firstName . ' ' . $dto->lastName,
            $dto->birthDate,
            $dto->gender,
            $dto->email,
            $dto->phoneNumber,
            $passwordHash,
            $now,
            $now,
        ]);

        return (int) $result[0]->UserID;
    }

    public function createCustomerUser(
        RegisterDto $dto,
        string $passwordHash,
        string $tokenHash,
        ?string $ipAddress,
        int $ttl
    ): string {
        try {

            $result = DB::select(
                'CALL sp_CreateCustomerUser(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [
                    $dto->firstName,
                    $dto->lastName,
                    $dto->birthDate,
                    $dto->gender,
                    $dto->email,
                    $dto->phoneNumber,
                    $passwordHash,
                    $dto->avatarUrl,
                    $tokenHash,
                    $ipAddress,
                    $ttl,
                ]
            );

            return $result[0]->PublicID;
        } catch (\Throwable $e) {

            throw new \Exception(
                'Failed to create customer user. ' . $e->getMessage(),
                0,
                $e
            );
        }
    }
    public function emailExists(string $email): bool
    {
        $result = DB::selectOne(
            "SELECT EXISTS(
            SELECT 1
            FROM Users
            WHERE Email = ?
              AND IsDeleted = 0
        ) AS ExistsFlag",
            [$email]
        );

        return (bool) $result->ExistsFlag;
    }

    public function phoneNumberExists(string $phoneNumber): bool
    {
        $result = DB::selectOne(
            "SELECT EXISTS(
            SELECT 1
            FROM Users
            WHERE PhoneNumber = ?
              AND IsDeleted = 0
        ) AS ExistsFlag",
            [$phoneNumber]
        );

        return (bool) $result->ExistsFlag;
    }
    public function getRoleIdByCode(string $code): ?int
    {
        $row = DB::selectOne("SELECT RoleID FROM Roles WHERE Code = ?", [$code]);

        return $row?->RoleID;
    }

    public function assignRole(int $userId, int $roleId): void
    {
        DB::insert(
            "INSERT INTO UserRoles (UserID, RoleID, AssignedAt, AssignedBy) VALUES (?, ?, ?, NULL)",
            [$userId, $roleId, now()->format('Y-m-d H:i:s')]
        );
    }

    public function createCustomerProfile(int $userId): void
    {
        $now = now()->format('Y-m-d H:i:s');

        DB::insert(
            "INSERT INTO CustomerProfiles (UserID, LoyaltyPoints, AcceptMarketingEmails, CreatedAt, UpdatedAt)
             VALUES (?, 0, 0, ?, ?)",
            [$userId, $now, $now]
        );
    }

    public function createVendorProfile(int $userId, string $storeName, ?string $description): void
    {
        $now = now()->format('Y-m-d H:i:s');

        DB::insert(
            "INSERT INTO VendorProfiles (
                UserID, StoreName, Description, Rating, ReviewCount,
                IdentityVerified, BusinessVerified, BankVerified,
                VerificationStatus, IsApproved, IsSuspended, CreatedAt, UpdatedAt
            )
            VALUES (?, ?, ?, 0, 0, 0, 0, 0, 0, 0, 0, ?, ?)",
            [$userId, $storeName, $description, $now, $now]
        );
    }

    public function findByEmail(string $email): ?UserDto
    {
        $row = DB::selectOne("SELECT * FROM Users WHERE Email = ? AND IsDeleted = 0", [$email]);

        return $row ? UserDto::fromDbRow($row, $this->getRolesForUser($row->UserID)) : null;
    }
    public function getLoginInfoByEmail(string $email): ?LoginInfoDto
    {
        $rows = DB::select('CALL GetLoginInfoByEmail(?)', [$email]);

        if (empty($rows)) {
            return null;
        }

        return LoginInfoDto::fromDbRows($rows);
    }
    public function findById(int $id): ?UserDto
    {
        $row = DB::selectOne("SELECT * FROM Users WHERE UserID = ?", [$id]);

        return $row ? UserDto::fromDbRow($row, $this->getRolesForUser($row->UserID)) : null;
    }

    public function getRoleForUser(int $userId): string
    {
        $result = DB::selectOne(
            "SELECT r.Code
         FROM UserRoles ur
         INNER JOIN Roles r ON r.RoleID = ur.RoleID
         WHERE ur.UserID = ?
         ORDER BY ur.AssignedAt DESC
         LIMIT 1",
            [$userId]
        );

        return $result?->Code;
    }

    public function updateLastLogin(int $id): void
    {
        DB::update(
            "UPDATE Users SET LastLoginAt = ? WHERE UserID = ?",
            [now()->format('Y-m-d H:i:s'), $id]
        );
    }

    public function createRefreshToken(
        int $userId,
        string $tokenHash,
        ?string $ipAddress,
        int $ttl
    ): void {
        DB::insert(
            'CALL sp_CreateRefreshToken(?, ?, ?, ?)',
            [$userId, $tokenHash, $ipAddress, $ttl]
        );
    }
    public function getReadNotificationsCount(int $userId): int
    {
        $row = DB::selectOne(
            "SELECT COUNT(*) AS Total FROM Notifications WHERE IsRead = 1 AND UserID = ?",
            [$userId]
        );

        return (int) $row->Total;
    }
    public function getUserStandardInformation(int $userId): ?UserStandardInfoDto
    {
        $row = DB::selectOne(
            "SELECT
            UserID, PublicID, FirstName, LastName, DisplayName, BirthDate, Gender,
            Email, PhoneNumber, AvatarURL, HasPassword, EmailVerified, PhoneVerified,
            IsActive, LastLoginAt, CreatedAt, UpdatedAt
         FROM Users
         WHERE UserID = ?
           AND IsDeleted = 0",
            [$userId]
        );

        return $row ? UserStandardInfoDto::fromDbRow($row) : null;
    }
    public function getUserStandardInformationByPublicID(string $publicID): ?UserStandardInfoDto
    {
        $row = DB::selectOne(
            "SELECT
            UserID, PublicID, FirstName, LastName, DisplayName, BirthDate, Gender,
            Email, PhoneNumber, AvatarURL, HasPassword, EmailVerified, PhoneVerified,
            IsActive, LastLoginAt, CreatedAt, UpdatedAt
         FROM Users
         WHERE PublicID = ?
           AND IsDeleted = 0",
            [$publicID]
        );

        return $row ? UserStandardInfoDto::fromDbRow($row) : null;
    }
    public function createVendor(
        VendorRegisterDto $dto,
        string $passwordHash,
        string $tokenHash,
        string $ipAddress,
        int $ttlDays
    ): array {
        $result = DB::select('CALL SP_CreateVendorUser(?,?,?,?,?,?,?,?,?,?,?,?,?)', [
            $dto->firstName,
            $dto->lastName,
            $dto->birthDate,
            $dto->gender,
            $dto->email,
            $dto->phoneNumber,
            $passwordHash,
            $dto->avatarUrl,
            $tokenHash,
            $ipAddress,
            $ttlDays,
            $dto->storeName,
            $dto->description,
        ]);

        $row = $result[0];

        return [
            'user_id'   => $row->UserID,
            'public_id' => $row->PublicID,
        ];
    }
}
