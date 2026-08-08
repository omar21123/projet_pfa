<?php

namespace App\DTOs\Promotion;

class GetPromotionsByProductDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $productId,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['UserPublicID'],
            productId: (int) $data['ProductID'],
        );
    }
}