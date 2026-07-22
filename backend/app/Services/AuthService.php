<?php

namespace App\Services;

use App\DTOs\Auth\LoginDto;
use App\DTOs\Auth\LoginInfoDto;
use App\DTOs\Auth\RegisterDto;
use App\DTOs\Auth\TokenResponseDto;
use App\DTOs\Auth\UserDto;
use App\DTOs\Auth\VendorRegisterDto;
use App\Repositories\Interface\UserRepositoryInterface;
use App\Services\Interface\AuthServiceInterface;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthService implements AuthServiceInterface
{
    public function __construct(private UserRepositoryInterface $userRepository)
    {
    }
    public function createCustomer(
    RegisterDto $dto,
    string $tokenHash,
    ?string $ipAddress,
    int $ttl
): string
{
    $passwordHash = Hash::make($dto->password);

    return $this->userRepository->createCustomerUser(
        $dto,
        $passwordHash,
        $tokenHash,
        $ipAddress,
        $ttl
    );
}

    public function login(LoginDto $dto): LoginInfoDto
    {
        $user = $this->userRepository->getLoginInfoByEmail($dto->email);

        if (!$user) {
            throw ValidationException::withMessages([
                'message' => ['Identifiants invalides.'],
            ]);
        }
        if(Hash::check($dto->password, $user->passwordHash))
        {
            return $user;
        }
        throw ValidationException::withMessages([
            'message' => ["Identifiants invalides."],
        ]);
    }

   public function createVendor(
    VendorRegisterDto $dto,
    string $tokenHash,
    string $ipAddress,
    int $ttlDays
): string {
    $passwordHash = Hash::make($dto->password);

    $result = $this->userRepository->createVendor($dto, $passwordHash, $tokenHash, $ipAddress, $ttlDays);

    return $result['public_id'];
}
}