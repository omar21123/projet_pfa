<?php

namespace App\Services\Interface;

use App\DTOs\Auth\LoginDto;
use App\DTOs\Auth\LoginInfoDto;
use App\DTOs\Auth\RegisterDto;
use App\DTOs\Auth\TokenResponseDto;

interface AuthServiceInterface
{
    public function register(RegisterDto $dto): TokenResponseDto;
    public function login(LoginDto $dto): LoginInfoDto;
  
     public function createCustomer(
    RegisterDto $dto,
    string $tokenHash,
    ?string $ipAddress,
    int $ttl
): string;
}