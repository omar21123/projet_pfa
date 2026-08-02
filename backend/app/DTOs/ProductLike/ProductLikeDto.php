<?php

namespace App\DTOs\ProductLike;

class ProductLikeDto
{
    public function __construct(
        public readonly int $productLikeId,
        public readonly int $productId,
        public readonly string $productName,
        public readonly ?string $productImage,
        public readonly float $basePrice,
        public readonly ?string $brandName,
        public readonly string $likedAt,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            productLikeId: (int) $row->ProductLikeID,
            productId: (int) $row->ProductID,
            productName: $row->ProductName,
            productImage: $row->ProductImage,
            basePrice: (float) $row->BasePrice,
            brandName: $row->BrandName,
            likedAt: $row->LikedAt,
        );
    }
}