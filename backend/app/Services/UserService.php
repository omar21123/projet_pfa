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
    public function getRolesForUser(int $userId): string
    {
        return $this->userRepository->getRoleForUser($userId);
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
