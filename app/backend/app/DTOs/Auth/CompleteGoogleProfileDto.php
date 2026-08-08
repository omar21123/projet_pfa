<?php

namespace App\DTOs\Auth;

readonly class CompleteGoogleProfileDto
{
    public function __construct(
        public string $role, // 'CUSTOMER' ou 'VENDOR'
        public ?string $phoneNumber,
        public ?string $birthDate,
        public ?int $gender,
        public ?string $storeName = null,
        public ?string $description = null,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            role: strtoupper($data['role'] ?? 'CUSTOMER'),
            phoneNumber: $data['phone_number'] ?? null,
            birthDate: $data['birth_date'] ?? null,
            gender: isset($data['gender']) ? (int) $data['gender'] : null,
            storeName: $data['store_name'] ?? null,
            description: $data['description'] ?? null,
        );
    }
}