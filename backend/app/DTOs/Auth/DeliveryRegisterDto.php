<?php
// app/DTOs/Auth/DeliveryRegisterDto.php

namespace App\DTOs\Auth;

readonly class DeliveryRegisterDto
{
    public function __construct(
        public string $firstName,
        public string $lastName,
        public string $email,
        public string $password,
        public ?string $phoneNumber,
        public ?string $vehicleType,
        public ?string $licensePlate,
        public ?int $assignedBy = null,
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
            vehicleType: $data['vehicle_type'] ?? null,
            licensePlate: $data['license_plate'] ?? null,
            assignedBy: $data['assigned_by'] ?? null,
        );
    }
}