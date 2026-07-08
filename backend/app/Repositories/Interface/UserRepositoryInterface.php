<?php

namespace App\Repositories\Interface;

use App\DTOs\Auth\RegisterDto;
use App\DTOs\Auth\UserDto;

interface UserRepositoryInterface
{
    public function createUser(RegisterDto $dto, string $passwordHash): int;

    public function getRoleIdByCode(string $code): ?int;

    public function assignRole(int $userId, int $roleId): void;

    public function createCustomerProfile(int $userId): void;

    public function createVendorProfile(int $userId, string $storeName, ?string $description): void;

    public function findByEmail(string $email): ?UserDto;

    public function findById(int $id): ?UserDto;

    public function updateLastLogin(int $id): void;

    public function getRolesForUser(int $userId): array;
}