<?php

namespace App\Services\Interface;

use App\DTOs\Auth\LoginDto;
use App\DTOs\Auth\RegisterDto;
use App\DTOs\Auth\TokenResponseDto;

interface AuthServiceInterface
{
    public function register(RegisterDto $dto): TokenResponseDto;

    public function login(LoginDto $dto): TokenResponseDto;
}