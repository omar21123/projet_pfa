<?php

namespace App\DTOs\Product;

class PublicProductInfoDto
{
    public function __construct(
        public readonly int $productId,
        public readonly string $productName,
        public readonly ?string $productDesc,
        public readonly float $basePrice,
        public readonly string $brandName,
        public readonly int $brandId,
        public readonly string $modelName,
        public readonly int $stock,
        public readonly int $totalOrders,
        public readonly int $totalWishlists,
        public readonly int $totalLikes,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            productId: (int) $row->ProductID,
            productName: $row->ProductName,
            productDesc: $row->ProductDesc,
            basePrice: (float) $row->BasePrice,
            brandName: $row->BrandName,
            brandId: (int) $row->BrandID,
            modelName: $row->ModelName,
            stock: (int) $row->Stock,
            totalOrders: (int) $row->TotalOrders,
            totalWishlists: (int) $row->TotalWishlists,
            totalLikes: (int) $row->TotalLikes,
        );
    }
}