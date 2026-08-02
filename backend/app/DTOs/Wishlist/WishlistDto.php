<?php
// App\DTOs\Wishlist\WishlistDto
namespace App\DTOs\Wishlist;

class WishlistDto
{
    /** @param WishlistItemDto[] $items */
    public function __construct(
        public readonly int $wishListId,
        public readonly string $name,
        public readonly bool $isDefault,
        public readonly string $createdAt,
        public readonly int $itemCount,
        public readonly array $items = [],
    ) {}

    public static function fromRow(object $row, array $items = []): self
    {
        return new self(
            wishListId: (int) $row->WishListID,
            name: $row->Name,
            isDefault: (bool) $row->IsDefault,
            createdAt: $row->CreatedAt,
            itemCount: (int) $row->ItemCount,
            items: $items,
        );
    }
}