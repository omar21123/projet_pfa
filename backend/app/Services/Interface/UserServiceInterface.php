<?php

namespace App\Services\Interface;

interface UserServiceInterface
{
   public function emailExists(string $email): bool;
   public function phoneNumberExists(string $phoneNumber): bool;
   public function updateLastLogin(int $id): void;
   public function createRefreshToken(
    int $userId,
    string $tokenHash,
    ?string $ipAddress,
    int $ttl
): void;
public function getReadNotificationsCount(int $userId): int;
}