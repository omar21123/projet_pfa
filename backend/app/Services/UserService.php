<?php

namespace App\Services;

use App\DTOs\Auth\RefreshTokenDTO;
use App\DTOs\Auth\UserStandardInfoDto;
use App\Repositories\Interface\UserRepositoryInterface;
use App\Repositories\sql\RefreshTokenRepository;
use App\Services\Interface\UserServiceInterface;

class UserService implements UserServiceInterface
{
    public function __construct(
        private UserRepositoryInterface $userRepository,
        private RefreshTokenRepository $refreshTokenRepository
    ) {}

    public function emailExists(string $email): bool
    {
        return $this->userRepository->emailExists($email);
    }

    public function phoneNumberExists(string $phoneNumber): bool
    {
        return $this->userRepository->phoneNumberExists($phoneNumber);
    }

    public function updateLastLogin(int $id): void
    {
        $this->userRepository->updateLastLogin($id);
    }

    public function createRefreshToken(
        int $userId,
        string $tokenHash,
        ?string $ipAddress,
        int $ttl
    ): void {
        $this->userRepository->createRefreshToken($userId, $tokenHash, $ipAddress, $ttl);
    }

    public function getReadNotificationsCount(int $userId): int
    {
        return $this->userRepository->getReadNotificationsCount($userId);
    }

    /**
     * Récupère le rôle de l'utilisateur.
     * Si aucun rôle n'est assigné (ex: pendant l'onboarding Google), 
     * retourne une chaîne vide '' pour éviter l'erreur PHP Return value must be of type string.
     */
    public function getRolesForUser(int $userId): string
    {
        $role = $this->userRepository->getRoleForUser($userId);

        return $role ?? '';
    }

    public function findActiveByTokenHash(string $tokenHash): ?RefreshTokenDTO
    {
        return $this->refreshTokenRepository->findActiveByTokenHash($tokenHash);
    }

    public function create(array $data): RefreshTokenDTO
    {
        return $this->refreshTokenRepository->create($data);
    }

    public function getUserStandardInformation(int $userId): ?UserStandardInfoDto
    {
        return $this->userRepository->getUserStandardInformation($userId);
    }

    public function getUserStandardInformationByPublicID(string $publicID): ?UserStandardInfoDto
    {
        return $this->userRepository->getUserStandardInformationByPublicID($publicID);
    }

    public function revokeByTokenHash(string $tokenHash, ?string $replacedByTokenHash = null): bool
    {
        return $this->refreshTokenRepository->revokeByTokenHash($tokenHash, $replacedByTokenHash);
    }
}