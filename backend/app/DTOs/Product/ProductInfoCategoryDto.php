<?php
// App\DTOs\Product\ProductInfoCategoryDto
namespace App\DTOs\Product;

class ProductInfoCategoryDto
{
    public function __construct(
        public readonly string $categoryName,
        public readonly bool $isPrimary,
    ) {}

    public function toArray(): array
    {
        return [
            'CategoryName' => $this->categoryName,
            'IsPrimary'    => $this->isPrimary,
        ];
    }
}