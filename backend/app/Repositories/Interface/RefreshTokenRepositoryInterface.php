<?php

namespace App\Repositories\Interface;

use App\DTOs\Auth\RefreshTokenDTO;

interface RefreshTokenRepositoryInterface
{
    /**
     * Raw lookup by hash — no revoked/expiry filtering.
     * Mirrors: SELECT * FROM UserRefreshTokens WHERE TokenHash = ?
     */
    public function findByTokenHash(string $tokenHash): ?RefreshTokenDTO;

    /**
     * Lookup by hash, only returning it if it's neither revoked nor expired.
     * This is what the refresh-token flow should actually use.
     */
    public function findActiveByTokenHash(string $tokenHash): ?RefreshTokenDTO;

    /**
     * @return array<int, RefreshTokenDTO>
     */
    public function findActiveForUser(int $userId): array;

    /**
     * @param array{
     *     user_id: int,
     *     user_device_id?: int|null,
     *     token_hash: string,
     *     ip_address?: string|null,
     *     expires_at: \DateTimeInterface|string,
     * } $data
     */
    public function create(array $data): RefreshTokenDTO;

    /**
     * Marks a single token as revoked, optionally pointing at its replacement
     * (rotation trail).
     */
    public function revokeByTokenHash(string $tokenHash, ?string $replacedByTokenHash = null): bool;

    /**
     * Revokes every active token for a user (e.g. "log out everywhere").
     * Returns the number of rows affected.
     */
    public function revokeAllForUser(int $userId): int;

    /**
     * Permanently deletes expired rows (housekeeping / scheduled cleanup).
     * Returns the number of rows deleted.
     */
    public function deleteExpired(): int;
}