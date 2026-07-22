<?php

namespace App\DTOs\Auth;

use Carbon\Carbon;

final class RefreshTokenDTO
{
    public function __construct(
        public readonly ?int $id,
        public readonly int $userId,
        public readonly ?int $userDeviceId,
        public readonly string $tokenHash,
        public readonly ?string $ipAddress,
        public readonly Carbon $expiresAt,
        public readonly bool $isRevoked,
        public readonly ?Carbon $revokedAt,
        public readonly ?string $replacedByTokenHash,
        public readonly ?Carbon $createdAt,
    ) {
    }

    /**
     * Maps a raw DB row (stdClass returned by DB::select / DB::selectOne)
     * from UserRefreshTokens into the DTO. Matches the same convention as
     * UserDto::fromDbRow().
     */
    public static function fromDbRow(object $row): self
    {
        return new self(
            id: isset($row->UserRefreshTokenID) ? (int) $row->UserRefreshTokenID : null,
            userId: (int) $row->UserID,
            userDeviceId: $row->UserDeviceID !== null ? (int) $row->UserDeviceID : null,
            tokenHash: $row->TokenHash,
            ipAddress: $row->IPAddress ?? null,
            expiresAt: Carbon::parse($row->ExpiresAt),
            isRevoked: (bool) $row->IsRevoked,
            revokedAt: $row->RevokedAt !== null ? Carbon::parse($row->RevokedAt) : null,
            replacedByTokenHash: $row->ReplacedByTokenHash ?? null,
            createdAt: $row->CreatedAt !== null ? Carbon::parse($row->CreatedAt) : null,
        );
    }

    public function isExpired(): bool
    {
        return $this->expiresAt->isPast();
    }

    public function isActive(): bool
    {
        return !$this->isRevoked && !$this->isExpired();
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->userId,
            'user_device_id' => $this->userDeviceId,
            'token_hash' => $this->tokenHash,
            'ip_address' => $this->ipAddress,
            'expires_at' => $this->expiresAt->toDateTimeString(),
            'is_revoked' => $this->isRevoked,
            'revoked_at' => $this->revokedAt?->toDateTimeString(),
            'replaced_by_token_hash' => $this->replacedByTokenHash,
            'created_at' => $this->createdAt?->toDateTimeString(),
        ];
    }
}