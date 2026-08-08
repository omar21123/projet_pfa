<?php

namespace App\DTOs\Product;

class GetMostSoldProductsDto
{
    public function __construct(
        public readonly ?string $userPublicId,
        public readonly int $limit,
        public readonly ?int $categoryId = null,
    
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['userPublicId'] ?? null,
            limit: (int) ($data['limit'] ?? 20),
            categoryId: isset($data['categoryId']) ? (int) $data['categoryId'] : null,
        );
    }
}