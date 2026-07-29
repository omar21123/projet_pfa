<?php

namespace App\DTOs\Promotion;

class GetPromotionsByCategoryDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $categoryId,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['UserPublicID'],
            categoryId: (int) $data['CategoryID'],
        );
    }
}