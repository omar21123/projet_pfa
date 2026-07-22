<?php

namespace App\Services;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\SignatureInvalidException;
use UnexpectedValueException;

/**
 * Generates and verifies the ACCESS token (short-lived JWT).
 * Carries UserID + Role(s) so the API can authorize requests
 * without hitting the database on every request.
 */
class AccessTokenService
{
    private string $secret;
    private string $algo = 'HS256';
    private int $ttl; // seconds

    public function __construct(?string $secret = null, ?int $ttl = null)
    {
        $this->secret = $secret ?? (string) env('JWT_SECRET');
        $this->ttl    = $ttl ?? (int) env('JWT_ACCESS_TTL', 900); // 15 min default

        if ($this->secret === '') {
            throw new \RuntimeException('JWT_SECRET is not configured.');
        }
    }

    /**
     * Generate a signed JWT access token.
     *
     * @param string       $userId  Maps to Users.PublicID
     * @param string|array $role    Single role code or array of roles
     */
    public function generate(string $userId, string|array $role): string
    {
        $now = time();

        $payload = [
            'sub'   => $userId,          // UserID
            'role'  => $role,            // Role(s)
            'type'  => 'access',
            'iat'   => $now,
            'nbf'   => $now,
            'exp'   => $now + $this->ttl,
            'jti'   => bin2hex(random_bytes(16)),
        ];

        return JWT::encode($payload, $this->secret, $this->algo);
    }

    /**
     * Verify + decode an access token. Throws on invalid/expired/tampered.
     */
    public function verify(string $token): object
    {
        try {
            $decoded = JWT::decode($token, new Key($this->secret, $this->algo));
        } catch (ExpiredException $e) {
            throw new \DomainException('Access token expired.', 401, $e);
        } catch (SignatureInvalidException $e) {
            throw new \DomainException('Invalid token signature.', 401, $e);
        } catch (UnexpectedValueException $e) {
            throw new \DomainException('Malformed token.', 401, $e);
        }

        if (($decoded->type ?? null) !== 'access') {
            throw new \DomainException('Token is not an access token.', 401);
        }

        return $decoded; // ->sub = UserID, ->role = Role(s)
    }
}