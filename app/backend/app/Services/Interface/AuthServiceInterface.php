<?php

namespace App\Services\Interface;

use App\DTOs\Auth\LoginDto;
use App\DTOs\Auth\LoginInfoDto;
use App\DTOs\Auth\RegisterDto;
use App\DTOs\Auth\TokenResponseDto;
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
}