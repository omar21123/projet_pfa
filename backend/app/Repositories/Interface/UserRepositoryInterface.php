<?php

namespace App\Repositories\Interface;

use App\DTOs\Auth\LoginInfoDto;
use App\DTOs\Auth\RegisterDto;
use App\DTOs\Auth\UserDto;
use App\DTOs\Auth\UserStandardInfoDto;
use App\DTOs\Auth\VendorRegisterDto;

interface UserRepositoryInterface
{
    public function createUser(RegisterDto $dto, string $passwordHash): int;
    public function createCustomerUser(
        RegisterDto $dto,
        string $passwordHash,
        string $tokenHash,
        ?string $ipAddress,
        int $ttl
    ): string;
    public function getRoleIdByCode(string $code): ?int;

    public function assignRole(int $userId, int $roleId): void;

    public function createCustomerProfile(int $userId): void;

    public function createVendorProfile(int $userId, string $storeName, ?string $description): void;

    public function findByEmail(string $email): ?UserDto;

    public function findById(int $id): ?UserDto;

    public function updateLastLogin(int $id): void;
// Retourne un tableau d'objets ou de résultats de rôles pour UserDto
    public function getRolesForUser(int $userId): array;

    // Optionnel : Si vous gardez aussi la version au singulier pour retourner une string
    public function getRoleForUser(int $userId): ?string;

    public function emailExists(string $email): bool;
    public function phoneNumberExists(string $phoneNumber): bool;
    public function getLoginInfoByEmail(string $email): ?LoginInfoDto;
    public function createRefreshToken(
        int $userId,
        string $tokenHash,
        ?string $ipAddress,
        int $ttl
    ): void;
    public function getReadNotificationsCount(int $userId): int;
    public function getUserStandardInformation(int $userId): ?UserStandardInfoDto;
    // App\Repositories\Interface\AuthRepositoryInterface

    public function createVendor(
        VendorRegisterDto $dto,
        string $passwordHash,
        string $tokenHash,
        string $ipAddress,
        int $ttlDays
    ): array;
    public function getUserStandardInformationByPublicID(string $publicID): ?UserStandardInfoDto;

}