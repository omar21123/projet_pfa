<?php

namespace App\DTOs\Auth;

class LoginInfoDto
{
    public function __construct(
        public readonly int $userId,
        public readonly string $publicId,
        public readonly string $displayName,
        public readonly ?string $phoneNumber,
        public readonly string $passwordHash,
        public readonly ?string $avatarUrl,
        public readonly bool $isActive,
        public readonly bool $emailVerified,
        public readonly bool $phoneVerified,
        public readonly array $roles, // e.g. ['customer', 'vendor']
    ) {
    }

    /**
     * Build the DTO from the rows returned by GetLoginInfoByEmail.
     * The SP joins Roles, so a user with N roles returns N rows —
     * every row shares the same user fields, only Code differs.
     */
    public static function fromDbRows(array $rows): self
    {
        $first = $rows[0];

        $roles = array_values(array_unique(
            array_map(fn ($row) => $row->Code, $rows)
        ));

        return new self(
            userId : $first->userId,
            publicId: $first->PublicID,
            displayName: $first->DisplayName,
            phoneNumber: $first->PhoneNumber,
            passwordHash: $first->PasswordHash,
            avatarUrl: $first->AvatarURL,
            isActive: (bool) $first->IsActive,
            emailVerified: (bool) $first->EmailVerified,
            phoneVerified: (bool) $first->PhoneVerified,
            roles: $roles,
        );
    }

    public function hasRole(string $code): bool
    {
        return in_array($code, $this->roles, true);
    }
}