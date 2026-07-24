<?php

namespace App\Services;

use App\DTOs\Auth\GoogleUserDto;
use App\DTOs\Auth\LoginDto;
use App\DTOs\Auth\LoginInfoDto;
use App\DTOs\Auth\RegisterDto;
use App\DTOs\Auth\VendorRegisterDto;
use App\Repositories\Interface\UserRepositoryInterface;
use App\Repositories\Interface\UsergoogleRepositoryInterface;
use App\Services\Interface\AuthServiceInterface;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthService implements AuthServiceInterface
{
    public function __construct(
        private UserRepositoryInterface $userRepository,
        private UsergoogleRepositoryInterface $usergoogleRepository,
        private AccessTokenService $accessTokenService,
        private RefreshTokenService $refreshTokenService,
    ) {}

    public function createCustomer(
        RegisterDto $dto,
        string $tokenHash,
        ?string $ipAddress,
        int $ttl
    ): string {
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

        if (Hash::check($dto->password, $user->passwordHash)) {
            return $user;
        }

        throw ValidationException::withMessages([
            'message' => ['Identifiants invalides.'],
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
    public function loginOrRegister(GoogleUserDto $dto, ?string $ipAddress, int $refreshTtlSeconds): array
    {
        $isNewUser = false;

        // 1) Compte déjà lié à ce GoogleID -> connexion directe
        $user = $this->usergoogleRepository->findByGoogleId($dto->googleId);

        if (!$user) {
            // 2) Un compte existe déjà avec cet email (inscrit via mot de passe) -> on lie le compte
            $existing = $this->userRepository->findByEmail($dto->email);

            if ($existing) {
                $this->usergoogleRepository->linkGoogleAccount($existing->id, $dto->googleId);
                $user = $this->userRepository->findById($existing->id);
            } else {
                // 3) Aucun compte -> création d'un nouveau customer
                $userId = $this->usergoogleRepository->createGoogleCustomer($dto);

                $roleId = $this->userRepository->getRoleIdByCode('CUSTOMER');
                $this->userRepository->assignRole($userId, $roleId);
                $this->userRepository->createCustomerProfile($userId);

                $user = $this->userRepository->findById($userId);
                $isNewUser = true;
            }
        }

        $this->userRepository->updateLastLogin($user->id);

        $refreshToken = $this->refreshTokenService->generate();
        $this->userRepository->createRefreshToken(
            $user->id,
            $refreshToken['token_hash'],
            $ipAddress,
            $refreshTtlSeconds
        );

        $accessToken = $this->accessTokenService->generate($user->publicId, 'CUSTOMER');

        return [
            'user' => $user,
            'access_token' => $accessToken,
            'refresh_token' => $refreshToken['token'],
            'is_new_user' => $isNewUser,
        ];
    }
}