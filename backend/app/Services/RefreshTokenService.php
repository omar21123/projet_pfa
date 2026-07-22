<?php

namespace App\Services;

/**
 * Generates the REFRESH token.
 * This is deliberately NOT a JWT — it's a random opaque string.
 * The raw token is sent to the client once; only its hash is
 * ever stored in the database (TokenHash column).
 *
 * This service does NOT touch the database — the caller is
 * responsible for saving the returned data (UserID, TokenHash,
 * ExpiresAt, IPAddress, UserAgent, etc.) to their own table.
 */
class RefreshTokenService
{
    private int $ttl; // seconds

    public function __construct(?int $ttl = null)
    {
        $this->ttl = $ttl ?? (int) env('JWT_REFRESH_TTL', 2592000); // 30 days default
    }

    /**
     * Generate a new refresh token.
     *
     * @return array{
     *     token: string,       // raw token -> send to client, never store this
     *     token_hash: string,  // sha256 hash -> store this in DB (TokenHash column)
     *     expires_at: int,     // unix timestamp -> store in DB (ExpiresAt column)
     * }
     */
    public function generate(): array
    {
        $raw  = bin2hex(random_bytes(64)); // 128-char cryptographically random hex string
        $hash = $this->hash($raw);

        return [
            'token'      => $raw,
            'token_hash' => $hash,
            'expires_at' => time() + $this->ttl,
        ];
    }

    /**
     * Hash a raw refresh token (same algorithm used in generate()).
     * Use this when a client sends back a refresh token, to look it
     * up in the DB by TokenHash instead of comparing raw strings.
     */
    public function hash(string $rawToken): string
    {
        return hash('sha256', $rawToken);
    }
}