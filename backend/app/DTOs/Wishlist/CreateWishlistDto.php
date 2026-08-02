<?php
// App\DTOs\Wishlist\CreateWishlistDto
namespace App\DTOs\Wishlist;

class CreateWishlistDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly ?string $name,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['userPublicId'],
            name: $data['name'] ?? null,
        );
    }
}