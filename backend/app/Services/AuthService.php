<?php

namespace App\Services;

use App\DTOs\Auth\CompleteGoogleProfileDto;
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
     *   role: string|null,
     *   is_new_user: bool,
     *   requires_onboarding: bool
     * }
     */
    public function loginOrRegister(
        GoogleUserDto $dto,
        ?string $ipAddress,
        int $refreshTtlSeconds,
        array $extraData = []
    ): array {
        $isNewUser = false;

        // 1) Vérifier si le compte existe déjà
        $user = $this->usergoogleRepository->findByGoogleId($dto->googleId);

        if (!$user) {
            $existing = $this->userRepository->findByEmail($dto->email);

            if ($existing) {
                $this->usergoogleRepository->linkGoogleAccount($existing->id, $dto->googleId);
                $user = $this->userRepository->findById($existing->id);
            } else {
                // Création du nouveau compte Google
                $userId = $this->usergoogleRepository->createGoogleCustomer($dto);
                $isNewUser = true;
                $user = $this->userRepository->findById($userId);
            }
        }

        // 2) Attribution du rôle + infos complémentaires.
        // 🟢 FIX : cette étape s'applique désormais à TOUT utilisateur sans rôle
        // (nouveau compte, compte existant lié à Google pour la 1ère fois, ou
        // compte déjà lié mais jamais onboardé) — pas seulement à la création.
        // Avant ce fix, un vendeur qui se reconnectait via Google sans être un
        // "nouveau compte" au sens strict ne recevait jamais son rôle/store_name.
        $currentRoles = $this->userRepository->getRolesForUser($user->id);
        $hasRoleAlready = !empty($currentRoles);

        if (!$hasRoleAlready && !empty($extraData['role'])) {
            $roleCode = strtoupper($extraData['role']);
            $roleId = $this->userRepository->getRoleIdByCode($roleCode);

            if ($roleId) {
                // Attribution du rôle
                $this->userRepository->assignRole($user->id, $roleId);

                // Mise à jour des informations secondaires
                $this->userRepository->updateGoogleUserProfile(
                    $user->id,
                    $extraData['phone_number'] ?? null,
                    $extraData['birth_date'] ?? null,
                    $extraData['gender'] ?? null
                );

                // Création du profil VENDOR ou CUSTOMER
                if ($roleCode === 'VENDOR' && !empty($extraData['store_name'])) {
                    $this->userRepository->createVendorProfile(
                        $user->id,
                        $extraData['store_name'],
                        $extraData['description'] ?? null
                    );
                } else {
                    $this->userRepository->createCustomerProfile($user->id);
                }
            }
        }

        // Récupération sécurisée du rôle (après attribution éventuelle ci-dessus)
        $roles = $this->userRepository->getRolesForUser($user->id);
        $userRole = null;

        if (!empty($roles)) {
            if (is_array($roles) && isset($roles[0])) {
                $firstRole = $roles[0];
                if (is_object($firstRole)) {
                    $userRole = $firstRole->Code ?? $firstRole->code ?? null;
                } elseif (is_string($firstRole)) {
                    $userRole = $firstRole;
                }
            } elseif (is_string($roles)) {
                $userRole = $roles;
            }
        }

        $requiresOnboarding = empty($userRole);

        $this->userRepository->updateLastLogin($user->id);

        $refreshToken = $this->refreshTokenService->generate();
        $this->userRepository->createRefreshToken(
            $user->id,
            $refreshToken['token_hash'],
            $ipAddress,
            $refreshTtlSeconds
        );

        $accessToken = $this->accessTokenService->generate($user->publicId, $userRole ?? 'ONBOARDING');

        return [
            'user'                => $user,
            'access_token'        => $accessToken,
            'refresh_token'       => $refreshToken['token'],
            'role'                => $userRole,
            'is_new_user'         => $isNewUser,
            'requires_onboarding' => $requiresOnboarding,
        ];
    }

    /**
     * Finalise l'inscription Google en assignant le rôle et les infos complémentaires.
     */
    public function completeGoogleProfile(string $publicId, CompleteGoogleProfileDto $dto): array
{
    $userInfo = $this->userRepository->getUserStandardInformationByPublicID($publicId);

    if (!$userInfo) {
        throw ValidationException::withMessages([
            'user' => ["Utilisateur introuvable."],
        ]);
    }

    $userId = $userInfo->userId;

    $this->userRepository->updateGoogleUserProfile(
        $userId,
        $dto->phoneNumber ?? null,
        $dto->birthDate ?? null,
        $dto->gender ?? null
    );

    $roleCode = strtoupper($dto->role);
    $roleId = $this->userRepository->getRoleIdByCode($roleCode);

    if (!$roleId) {
        throw ValidationException::withMessages([
            'role' => ["Le rôle '{$roleCode}' n'existe pas ou n'a pas été trouvé."],
        ]);
    }

    $this->userRepository->assignRole($userId, $roleId);

    if ($roleCode === 'VENDOR') {
        if (empty($dto->storeName)) {
            throw ValidationException::withMessages([
                'store_name' => ['Le nom de la boutique est requis pour un vendeur.'],
            ]);
        }
        $this->userRepository->createVendorProfile($userId, $dto->storeName, $dto->description ?? null);
    } else {
        $this->userRepository->createCustomerProfile($userId);
    }

    $user = $this->userRepository->findById($userId);

    $newAccessToken = $this->accessTokenService->generate($user->publicId, $roleCode);

    return [
        'user'         => $user,
        'role'         => $roleCode,
        'access_token' => $newAccessToken,
    ];
}
}