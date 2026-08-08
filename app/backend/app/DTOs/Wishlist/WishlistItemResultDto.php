<?php
// App\DTOs\Wishlist\WishlistItemResultDto
namespace App\DTOs\Wishlist;

class WishlistItemResultDto
{
    public function __construct(
        public readonly int $wishListItemId,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            wishListItemId: (int) $row->wishListItemId,
        );
    }
}