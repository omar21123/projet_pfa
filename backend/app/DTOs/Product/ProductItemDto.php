<?php

namespace App\DTOs\Product;

class ProductItemDto
{
    public function __construct(
        public readonly int $productId,
        public readonly string $productName,
        public readonly ?string $productDefaultImage,
        public readonly ?string $description,
        public readonly float $defaultPrice,
        public readonly ?string $brandName,
        public readonly ?string $brandLogo,
        public readonly ?string $modelName,
        public readonly int $totalWishlist,
        public readonly int $totalLikes,
        public readonly int $totalOrders,
        public readonly bool $isLiked,
        public readonly bool $isWishedList,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            productId: (int) $row->ProductID,
            productName: $row->ProductName,
            productDefaultImage: $row->ProductDefaultImage,
            description: $row->Description,
            defaultPrice: (float) $row->DefaultPrice,
            brandName: $row->BrandName,
            brandLogo: $row->BrandLogo,
            modelName: $row->ModelName,
            totalWishlist: (int) $row->TotalWishlist,
            totalLikes: (int) $row->TotalLikes,
            totalOrders: (int) $row->TotalOrders,
            isLiked: (bool) $row->IsLiked,
            isWishedList: (bool) $row->IsWishedList,
        );
    }

    public function toArray(): array
    {
        return [
            'ProductID'      => $this->productId,
            'ProductName'    => $this->productName,
            'ProductImage'   => $this->productDefaultImage,
            'Description'    => $this->description,
            'Price'          => $this->defaultPrice,
            'Brand'          => ['name' => $this->brandName, 'logo' => $this->brandLogo],
            'ModelName'      => $this->modelName,
            'TotalWishlist'  => $this->totalWishlist,
            'TotalLikes'     => $this->totalLikes,
            'TotalOrders'    => $this->totalOrders,
            'IsLiked'        => $this->isLiked,
            'IsWishedList'   => $this->isWishedList,
        ];
    }
}