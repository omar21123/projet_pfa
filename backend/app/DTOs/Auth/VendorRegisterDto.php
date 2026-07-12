<?php

namespace App\DTOs\Auth;

readonly class VendorRegisterDto
{
    public function __construct(
        public string $firstName,
        public string $lastName,
        public string $email,
        public string $password,
        public ?string $phoneNumber,
        public ?string $birthDate,
        public ?int $gender,
        public ?string $avatarUrl,
        public string $storeName,
        public ?string $description,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            firstName: $data['first_name'],
            lastName: $data['last_name'],
            email: $data['email'],
            password: $data['password'],
            phoneNumber: $data['phone_number'] ?? null,
            birthDate: $data['birth_date'] ?? null,
            gender: $data['gender'] ?? null,
            avatarUrl: $data['avatar_url'] ?? null,
            storeName: $data['store_name'],
            description: $data['description'] ?? null,
        );
    }
}