<?php

namespace App\Services\Interface;

use App\DTOs\Auth\GoogleUserDto;
use App\DTOs\Auth\LoginDto;
use App\DTOs\Auth\LoginInfoDto;
use App\DTOs\Auth\RegisterDto;
use App\DTOs\Auth\VendorRegisterDto;

interface AuthServiceInterface
{
    public function login(LoginDto $dto): LoginInfoDto;

    public function createCustomer(
        RegisterDto $dto,
        string $tokenHash,
        ?string $ipAddress,
        int $ttl
    ): string;

    public function createVendor(
        VendorRegisterDto $dto,
        string $tokenHash,
        string $ipAddress,
        int $ttlDays
    ): string;

    /**
     * Connecte l'utilisateur s'il existe déjà (par GoogleID ou par email),
     * sinon crée un nouveau compte CUSTOMER, puis génère les tokens.
     *
     * @return array{
     *   user: \App\DTOs\Auth\UserDto,
     *   access_token: string,
     *   refresh_token: string,
     *   is_new_user: bool
     * }
     */
    public function loginOrRegister(GoogleUserDto $dto, ?string $ipAddress, int $refreshTtlSeconds): array;
}