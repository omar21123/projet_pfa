<?php
namespace App\DTOs\Product;

class ProductSearchITemScrorredDto
{
    /**
     * @param ProductItemDto[] $items
     */
    public function __construct(
        public readonly array $items,
        public readonly int $score,
    ) {}
}