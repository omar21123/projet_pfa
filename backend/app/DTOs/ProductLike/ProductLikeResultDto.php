<?php

namespace App\DTOs\ProductLike;

class ProductLikeResultDto
{
    public function __construct(
        public readonly int $productLikeId,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            productLikeId: (int) $row->productLikeId,
        );
    }
}