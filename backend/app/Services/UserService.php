<?php

namespace App\Services;

use App\Repositories\Interface\UserRepositoryInterface;
use App\Services\Interface\UserServiceInterface;

class UserService implements UserServiceInterface
{
    public function __construct(
        private UserRepositoryInterface $userRepository
    ) {
    }

    public function emailExists(string $email): bool
    {
        return $this->userRepository->emailExists($email);
    }

    public function phoneNumberExists(string $phoneNumber): bool
    {
        return $this->userRepository->phoneNumberExists($phoneNumber);
    }
    public function updateLastLogin(int $id): void {
        $this->userRepository->updateLastLogin($id);
    }
    public function createRefreshToken(
    int $userId,
    string $tokenHash,
    ?string $ipAddress,
    int $ttl
): void{
        $this->userRepository->createRefreshToken($userId, $tokenHash, $ipAddress, $ttl);
}
     
    public function getReadNotificationsCount(int $userId): int
    {
        return $this->userRepository->getReadNotificationsCount($userId);
    }
}