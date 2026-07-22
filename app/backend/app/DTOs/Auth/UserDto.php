<?php

namespace App\DTOs\Auth;

readonly class UserDto
{
    public function __construct(
        public int $id,
        public string $publicId,
        public string $firstName,
        public string $lastName,
        public ?string $displayName,
        public string $email,
        public ?string $phoneNumber,
        public ?string $avatarUrl,
        public bool $emailVerified,
        public bool $isActive,
        public bool $isDeleted,
        public ?string $passwordHash,   // reste interne, jamais exposé par UserResource
        public array $roles,            // ex: ['customer']
        public ?string $createdAt,
    ) {
    }

    /**
     * Hydrate depuis une ligne stdClass renvoyée par DB::select() (colonnes PascalCase),
     * + les lignes de la table Roles déjà récupérées séparément.
     */
    public static function fromDbRow(object $row, array $roles = []): self
    {
        return new self(
            id: $row->UserID,
            publicId: $row->PublicID,
            firstName: $row->FirstName,
            lastName: $row->LastName,
            displayName: $row->DisplayName,
            email: $row->Email,
            phoneNumber: $row->PhoneNumber,
            avatarUrl: $row->AvatarURL,
            emailVerified: (bool) $row->EmailVerified,
            isActive: (bool) $row->IsActive,
            isDeleted: (bool) $row->IsDeleted,
            passwordHash: $row->PasswordHash ?? null,
            roles: array_map(fn ($r) => $r->Code, $roles),
            createdAt: $row->CreatedAt,
        );
    }
}