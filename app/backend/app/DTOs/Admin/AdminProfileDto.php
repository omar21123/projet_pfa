<?php

namespace App\DTOs\Admin;

use stdClass;

readonly class AdminProfileDto
{
    public function __construct(
        public string $publicId,
        public string $firstName,
        public string $lastName,
        public string $displayName,
        public string $email,
        public ?string $phoneNumber,
        public ?string $avatarUrl,
        public ?string $lastLoginAt,
        public string $employeeNumber,
        public string $cin,
        public string $position,
        public int $status,
        public bool $identityVerified,
        public string $hireDate,
    ) {
    }

    /**
     * Map les données brutes SQL (PascalCase) vers le DTO (camelCase).
     */
    public static function fromDbRow(stdClass $row): self
    {
        return new self(
            publicId: $row->PublicID,
            firstName: $row->FirstName,
            lastName: $row->LastName,
            displayName: $row->DisplayName,
            email: $row->Email,
            phoneNumber: $row->PhoneNumber ?? null,
            avatarUrl: $row->AvatarURL ?? null,
            lastLoginAt: $row->LastLoginAt ?? null,
            employeeNumber: $row->EmployeeNumber,
            cin: $row->CIN,
            position: $row->Position,
            status: (int) $row->Status,
            identityVerified: (bool) $row->IdentityVerified,
            hireDate: $row->HireDate,
        );
    }
}