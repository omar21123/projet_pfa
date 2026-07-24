<?php

namespace App\DTOs\Auth;

/**
 * DTO représentant les infos d'un utilisateur authentifié via Google,
 * qu'elles viennent de Socialite (flow web/redirect) ou d'un id_token
 * vérifié manuellement (flow mobile / Google Identity Services).
 */
class GoogleUserDto
{
    public function __construct(
        public readonly string $googleId,
        public readonly string $email,
        public readonly string $firstName,
        public readonly string $lastName,
        public readonly ?string $avatarUrl,
        public readonly bool $emailVerified = true,
    ) {}

    /**
     * Construit le DTO à partir d'un utilisateur Socialite (flow web).
     */
    public static function fromSocialite(\Laravel\Socialite\Contracts\User $googleUser): self
    {
        $name = trim((string) $googleUser->getName());
        $parts = $name !== '' ? explode(' ', $name, 2) : ['Utilisateur', ''];

        return new self(
            googleId: (string) $googleUser->getId(),
            email: (string) $googleUser->getEmail(),
            firstName: $parts[0] ?? 'Utilisateur',
            lastName: $parts[1] ?? '',
            avatarUrl: $googleUser->getAvatar(),
        );
    }

    /**
     * Construit le DTO à partir du payload retourné par
     * https://oauth2.googleapis.com/tokeninfo (flow mobile / id_token).
     */
    public static function fromTokenInfo(array $payload): self
    {
        return new self(
            googleId: (string) ($payload['sub'] ?? ''),
            email: (string) ($payload['email'] ?? ''),
            firstName: (string) ($payload['given_name'] ?? 'Utilisateur'),
            lastName: (string) ($payload['family_name'] ?? ''),
            avatarUrl: $payload['picture'] ?? null,
            emailVerified: filter_var($payload['email_verified'] ?? true, FILTER_VALIDATE_BOOLEAN),
        );
    }
}