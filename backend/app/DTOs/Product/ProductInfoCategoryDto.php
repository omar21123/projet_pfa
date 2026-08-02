<?php

namespace App\DTOs\Product;

class ProductInfoCategoryDto
{
    public function __construct(
        public readonly string $categoryName,
        public readonly bool $isPrimary,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            categoryName: $row->Name,
            isPrimary: (bool) $row->IsPrimary,
        );
    }

    public function toArray(): array
    {
        return [
            'CategoryName' => $this->categoryName,
            'IsPrimary'    => $this->isPrimary,
        ];
    }
}