<?php

namespace App\DTOs\Auth;

use Carbon\Carbon;

final class UserStandardInfoDto
{
    public function __construct(
        public readonly int $userId,
        public readonly string $publicId,
        public readonly ?string $firstName,
        public readonly ?string $lastName,
        public readonly ?string $displayName,
        public readonly ?Carbon $birthDate,
        public readonly ?int $gender,
        public readonly string $email,
        public readonly ?string $phoneNumber,
        public readonly ?string $avatarUrl,
        public readonly bool $hasPassword,
        public readonly bool $emailVerified,
        public readonly bool $phoneVerified,
        public readonly bool $isActive,
        public readonly ?Carbon $lastLoginAt,
        public readonly Carbon $createdAt,
        public readonly Carbon $updatedAt,
    ) {
    }

    /**
     * Maps a raw DB row (stdClass returned by DB::selectOne) from the
     * Users table into the DTO. Assumes the SELECT already excludes
     * PasswordHash, IsDeleted — see UserRepository::getUserStandardInformation().
     */
    public static function fromDbRow(object $row): self
    {
        return new self(
            userId: (int) $row->UserID,
            publicId: $row->PublicID,
            firstName: $row->FirstName,
            lastName: $row->LastName,
            displayName: $row->DisplayName,
            birthDate: $row->BirthDate !== null ? Carbon::parse($row->BirthDate) : null,
            gender: $row->Gender !== null ? (int) $row->Gender : null,
            email: $row->Email,
            phoneNumber: $row->PhoneNumber,
            avatarUrl: $row->AvatarURL,
            hasPassword: (bool) $row->HasPassword,
            emailVerified: (bool) $row->EmailVerified,
            phoneVerified: (bool) $row->PhoneVerified,
            isActive: (bool) $row->IsActive,
            lastLoginAt: $row->LastLoginAt !== null ? Carbon::parse($row->LastLoginAt) : null,
            createdAt: Carbon::parse($row->CreatedAt),
            updatedAt: Carbon::parse($row->UpdatedAt),
        );
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'public_id' => $this->publicId,
            'first_name' => $this->firstName,
            'last_name' => $this->lastName,
            'display_name' => $this->displayName,
            'birth_date' => $this->birthDate?->toDateString(),
            'gender' => $this->gender,
            'email' => $this->email,
            'phone_number' => $this->phoneNumber,
            'avatar_url' => $this->avatarUrl,
            'has_password' => $this->hasPassword,
            'email_verified' => $this->emailVerified,
            'phone_verified' => $this->phoneVerified,
            'is_active' => $this->isActive,
            'last_login_at' => $this->lastLoginAt?->toDateTimeString(),
            'created_at' => $this->createdAt->toDateTimeString(),
            'updated_at' => $this->updatedAt->toDateTimeString(),
        ];
    }
}