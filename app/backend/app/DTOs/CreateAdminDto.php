<?
namespace App\DTOs;

class CreateAdminDto
{
    public function __construct(
        public string $firstName,
        public string $lastName,
        public string $email,
        public string $password,
        public ?string $phoneNumber = null
    ) {
    }

    public static function fromRequest($request): self
    {
        return new self(
            firstName: $request->validated('FirstName'),
            lastName: $request->validated('LastName'),
            email: $request->validated('Email'),
            password: $request->validated('Password'),
            phoneNumber: $request->validated('PhoneNumber')
        );
    }
}