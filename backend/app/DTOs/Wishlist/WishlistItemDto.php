<?php
// App\DTOs\Wishlist\WishlistItemDto
namespace App\DTOs\Wishlist;

class WishlistItemDto
{
    public function __construct(
        public readonly int $wishListItemId,
        public readonly int $wishListId,
        public readonly int $productId,
        public readonly string $productName,
        public readonly ?string $productImage,
        public readonly float $basePrice,
        public readonly ?string $brandName,
        public readonly string $createdAt,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            wishListItemId: (int) $row->WishListItemID,
            wishListId: (int) $row->WishListID,
            productId: (int) $row->ProductID,
            productName: $row->ProductName,
            productImage: $row->ProductImage,
            basePrice: (float) $row->BasePrice,
            brandName: $row->BrandName,
            createdAt: $row->CreatedAt,
        );
    }
}