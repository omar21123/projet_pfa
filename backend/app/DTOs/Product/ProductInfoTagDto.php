<?php
// App\DTOs\Product\ProductInfoTagDto
namespace App\DTOs\Product;

class ProductInfoTagDto
{
    public function __construct(
        public readonly int $tagId,
        public readonly string $tagName,
    ) {}

    public function toArray(): array
    {
        return [
            'TagID'   => $this->tagId,
            'TagName' => $this->tagName,
        ];
    }
}