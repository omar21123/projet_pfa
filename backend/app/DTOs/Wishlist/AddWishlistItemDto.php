<?php
// App\DTOs\Wishlist\AddWishlistItemDto
namespace App\DTOs\Wishlist;

class AddWishlistItemDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $wishListId,
        public readonly int $productId,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['userPublicId'],
            wishListId: $data['wishListId'],
            productId: $data['productId'],
        );
    }
}