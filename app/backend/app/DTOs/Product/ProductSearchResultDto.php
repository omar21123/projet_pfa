<?php

namespace App\DTOs\Product;

class ProductSearchResultDto
{
    /**
     * @param ProductItemDto[] $items
     */
    public function __construct(
        public readonly array $items,
        public readonly int $total,
    ) {}
}
