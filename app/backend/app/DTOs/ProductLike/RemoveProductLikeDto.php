<?php

namespace App\DTOs\ProductLike;

class RemoveProductLikeDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $productId,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['userPublicId'],
            productId: (int) $data['productId'],
        );
    }
}