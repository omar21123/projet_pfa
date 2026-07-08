<?php

namespace App\Repositories\sql;

use App\DTOs\Auth\RegisterDto;
use App\DTOs\Auth\UserDto;
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

    public function findById(int $id): ?UserDto
    {
        $row = DB::selectOne("SELECT * FROM Users WHERE UserID = ?", [$id]);

        return $row ? UserDto::fromDbRow($row, $this->getRolesForUser($row->UserID)) : null;
    }

    public function updateLastLogin(int $id): void
    {
        DB::update(
            "UPDATE Users SET LastLoginAt = ? WHERE UserID = ?",
            [now()->format('Y-m-d H:i:s'), $id]
        );
    }

    public function getRolesForUser(int $userId): array
    {
        return DB::select(
            "SELECT r.RoleID, r.Name, r.Code
             FROM UserRoles ur
             INNER JOIN Roles r ON r.RoleID = ur.RoleID
             WHERE ur.UserID = ?",
            [$userId]
        );
    }
}
