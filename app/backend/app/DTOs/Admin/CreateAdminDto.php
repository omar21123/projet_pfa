<?php

namespace App\DTOs\Admin;

class CreateAdminDto
{
    public function __construct(
        public string $firstName,
        public string $lastName,
        public string $email,
        public string $password,
        public ?string $phoneNumber = null,
        public ?string $birthDate = null,
        public ?int $gender = null,
        public ?string $cin = null,
        public ?string $employeeNumber = null,
        public ?string $position = null,
        public ?string $hireDate = null,
        public bool $identityVerified = true,
        public ?string $avatarUrl = null,
        public ?string $tokenHash = null,
        public ?string $ipAddress = null,
        public int $ttlDays = 7
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            firstName: self::getValue($data, 'first_name', 'FirstName'),
            lastName: self::getValue($data, 'last_name', 'LastName'),
            email: self::getValue($data, 'email', 'Email'),
            password: self::getValue($data, 'password', 'Password'),
            phoneNumber: self::getValue($data, 'phone_number', 'PhoneNumber'),
            birthDate: self::getValue($data, 'birth_date', 'BirthDate'),
            gender: self::getValue($data, 'gender', 'Gender'),
            cin: self::getValue($data, 'cin', 'CIN'),
            employeeNumber: self::getValue($data, 'employee_number', 'EmployeeNumber'),
            position: self::getValue($data, 'position', 'Position'),
            hireDate: self::getValue($data, 'hire_date', 'HireDate') ?? now()->toDateTimeString(),
            identityVerified: (bool) (self::getValue($data, 'identity_verified', 'IdentityVerified') ?? true),
            avatarUrl: self::getValue($data, 'avatar_url', 'AvatarURL'),
            tokenHash: self::getValue($data, 'token_hash', 'TokenHash'),
            ipAddress: self::getValue($data, 'ip_address', 'IPAddress'),
            ttlDays: (int) (self::getValue($data, 'ttl_days', 'TTL') ?? 7)
        );
    }

    public static function fromRequest($request): self
    {
        $data = $request->validated();
        $data['ip_address'] ??= $request->ip();

        return self::fromArray($data);
    }

    private static function getValue(array $data, string ...$keys): mixed
    {
        foreach ($keys as $key) {
            if (array_key_exists($key, $data)) {
                return $data[$key];
            }
        }

        return null;
    }
}