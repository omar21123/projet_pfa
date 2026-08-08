<?php

namespace App\DTOs\Product;

class GetNewProductsDto
{
    public function __construct(
        public readonly ?string $userPublicId,
        public readonly ?int $daysBack = 7,
        public readonly ?int $limit = 20,
        public readonly ?int $categoryId = null,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['userPublicId'] ?? null,
            daysBack: isset($data['daysBack']) ? (int) $data['daysBack'] : 7,
            limit: isset($data['limit']) ? (int) $data['limit'] : 20,
            categoryId: isset($data['categoryId']) ? (int) $data['categoryId'] : null,
        );
    }
}