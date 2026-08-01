<?php
// App\DTOs\Wishlist\DeleteWishlistDto
namespace App\DTOs\Wishlist;

class DeleteWishlistDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $wishListId,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['userPublicId'],
            wishListId: $data['wishListId'],
        );
    }
}