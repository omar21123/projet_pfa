<?php

namespace App\Services\Interface;

use App\DTOs\Auth\RefreshTokenDTO;
use App\DTOs\Auth\UserStandardInfoDto;

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
 public function getRolesForUser(int $userId): string;
  public function findActiveByTokenHash(string $tokenHash): ?RefreshTokenDTO;
    /**
     * this is not for creation New USer , But to create a new Refresh Token for an existing user
     * (rotation trail).
     */
  public function create(array $data): RefreshTokenDTO;
  public function getUserStandardInformation(int $userId): ?UserStandardInfoDto;
   /**
     * Marks a single token as revoked, optionally pointing at its replacement
     * (rotation trail).
     */
    public function revokeByTokenHash(string $tokenHash, ?string $replacedByTokenHash = null): bool;
    public function getUserStandardInformationByPublicID(string $publicID): ?UserStandardInfoDto;



}