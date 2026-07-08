<?php

namespace App\DTOs\Auth;

readonly class RegisterDto
{
    public function __construct(
        public string $firstName,
        public string $lastName,
        public string $email,
        public string $password,
        public ?string $phoneNumber,
        public ?string $birthDate,
        public ?int $gender,
        public string $accountType,     // 'customer' | 'vendor'
        public ?string $storeName,
        public ?string $storeDescription,
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
            accountType: $data['account_type'],
            storeName: $data['store_name'] ?? null,
            storeDescription: $data['store_description'] ?? null,
        );
    }
}