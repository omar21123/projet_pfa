<?php

namespace App\Services;

use App\DTOs\Auth\LoginDto;
use App\DTOs\Auth\RegisterDto;
use App\DTOs\Auth\TokenResponseDto;
use App\DTOs\Auth\UserDto;
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

    public function login(LoginDto $dto): TokenResponseDto
    {
        $user = $this->userRepository->findByEmail($dto->email);

        if (!$user || !Hash::check($dto->password, $user->passwordHash)) {
            throw ValidationException::withMessages([
                'email' => ['Identifiants invalides.'],
            ]);
        }

        if (!$user->isActive || $user->isDeleted) {
            throw ValidationException::withMessages([
                'email' => ['Ce compte est désactivé.'],
            ]);
        }

        $this->userRepository->updateLastLogin($user->id);

        return new TokenResponseDto($user, $this->generateToken($user));
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
}