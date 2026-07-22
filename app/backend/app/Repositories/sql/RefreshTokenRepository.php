<?php

namespace App\Repositories\sql;

use App\DTOs\Auth\RefreshTokenDTO;
use App\Repositories\Interface\RefreshTokenRepositoryInterface;
use Illuminate\Support\Facades\DB;

/**
 * ⚠️ SQL brut — pas d'Eloquent. Colonnes en PascalCase pour correspondre
 * exactement au schéma de la table UserRefreshTokens.
 */
class RefreshTokenRepository implements RefreshTokenRepositoryInterface
{
    public function findByTokenHash(string $tokenHash): ?RefreshTokenDTO
    {
        $row = DB::selectOne(
            "SELECT * FROM UserRefreshTokens WHERE TokenHash = ?",
            [$tokenHash]
        );

        return $row ? RefreshTokenDTO::fromDbRow($row) : null;
    }

    public function findActiveByTokenHash(string $tokenHash): ?RefreshTokenDTO
    {
        $row = DB::selectOne(
            "SELECT * FROM UserRefreshTokens
             WHERE TokenHash = ?
               AND IsRevoked = 0
               AND ExpiresAt > UTC_TIMESTAMP()",
            [$tokenHash]
        );

        return $row ? RefreshTokenDTO::fromDbRow($row) : null;
    }

    public function findActiveForUser(int $userId): array
    {
        $rows = DB::select(
            "SELECT * FROM UserRefreshTokens
             WHERE UserID = ?
               AND IsRevoked = 0
               AND ExpiresAt > UTC_TIMESTAMP()
             ORDER BY CreatedAt DESC",
            [$userId]
        );

        return array_map(
            fn (object $row) => RefreshTokenDTO::fromDbRow($row),
            $rows
        );
    }

    public function create(array $data): RefreshTokenDTO
    {
        DB::insert(
            "INSERT INTO UserRefreshTokens (UserID, UserDeviceID, TokenHash, IPAddress, ExpiresAt)
             VALUES (?, ?, ?, ?, ?)",
            [
                $data['user_id'],
                $data['user_device_id'] ?? null,
                $data['token_hash'],
                $data['ip_address'] ?? null,
                $data['expires_at'],
            ]
        );

        $id = (int) DB::getPdo()->lastInsertId();

        $row = DB::selectOne(
            "SELECT * FROM UserRefreshTokens WHERE UserRefreshTokenID = ?",
            [$id]
        );

        return RefreshTokenDTO::fromDbRow($row);
    }

    public function revokeByTokenHash(string $tokenHash, ?string $replacedByTokenHash = null): bool
    {
        $affected = DB::update(
            "UPDATE UserRefreshTokens
             SET IsRevoked = 1, RevokedAt = UTC_TIMESTAMP(), ReplacedByTokenHash = ?
             WHERE TokenHash = ?
               AND IsRevoked = 0",
            [$replacedByTokenHash, $tokenHash]
        );
        return $affected > 0;
    }

    public function revokeAllForUser(int $userId): int
    {
        return DB::update(
            "UPDATE UserRefreshTokens
             SET IsRevoked = 1, RevokedAt = UTC_TIMESTAMP()
             WHERE UserID = ?
               AND IsRevoked = 0",
            [$userId]
        );
    }

    public function deleteExpired(): int
    {
        return DB::delete(
            "DELETE FROM UserRefreshTokens WHERE ExpiresAt < UTC_TIMESTAMP()"
        );
    }
}