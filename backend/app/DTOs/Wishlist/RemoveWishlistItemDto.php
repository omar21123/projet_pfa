<?php
// App\DTOs\Wishlist\RemoveWishlistItemDto
namespace App\DTOs\Wishlist;

class RemoveWishlistItemDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $wishListItemId,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['userPublicId'],
            wishListItemId: $data['wishListItemId'],
        );
    }
}