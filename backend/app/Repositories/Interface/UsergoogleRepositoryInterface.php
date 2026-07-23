<?php

namespace App\Repositories\Interface;

use App\DTOs\Auth\LoginInfoDto;
use App\DTOs\Auth\RegisterDto;
use App\DTOs\Auth\UserDto;
use App\DTOs\Auth\UserStandardInfoDto;
use App\DTOs\Auth\VendorRegisterDto;
use App\DTOs\Auth\GoogleUserDto;

 interface UsergoogleRepositoryInterface{

public function findByGoogleId(string $googleId): ?UserDto;
public function linkGoogleAccount(int $userId, string $googleId): void;
public function createGoogleCustomer(GoogleUserDto $dto): int;}