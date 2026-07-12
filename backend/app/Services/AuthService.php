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
    public function register(RegisterDto $dto): TokenResponseDto
    {
        return DB::transaction(function () use ($dto) {
            $passwordHash = Hash::make($dto->password);

            $userId = $this->userRepository->createUser($dto, $passwordHash);

            $roleId = $this->userRepository->getRoleIdByCode($dto->accountType);

            if (!$roleId) {
                throw ValidationException::withMessages([
                    'account_type' => ["Le rôle '{$dto->accountType}' n'existe pas dans la table Roles."],
                ]);
            }

            $this->userRepository->assignRole($userId, $roleId);

            if ($dto->accountType === 'vendor') {
                $this->userRepository->createVendorProfile($userId, $dto->storeName, $dto->storeDescription);
            } else {
                $this->userRepository->createCustomerProfile($userId);
            }

            $user = $this->userRepository->findById($userId);

            return new TokenResponseDto($user, $this->generateToken($user));
        });
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
            'message' => ['Identifiants invalides.'],
        ]);
    }

    private function generateToken(UserDto $user): string
    {
        $payload = [
            'iss' => config('app.url'),
            'sub' => $user->id,
            'roles' => $user->roles,
            'iat' => time(),
            'exp' => time() + 60 * 60 * 24, // 24h — ajuste selon ton besoin
        ];

        return JWT::encode($payload, config('app.jwt_secret'), 'HS256');
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