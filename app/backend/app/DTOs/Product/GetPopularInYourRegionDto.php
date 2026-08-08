<?php

namespace App\DTOs\Product;

class GetPopularInYourRegionDto
{
    public function __construct(
        public readonly ?string $userPublicId,
        public readonly ?string $countryCode,
        public readonly ?string $region,
        public readonly ?int $limit = 20,
        public readonly ?int $categoryId = null,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['userPublicId'] ?? null,
            countryCode: $data['countryCode'] ?? null,
            region: $data['region'] ?? null,
            limit: isset($data['limit']) ? (int) $data['limit'] : 20,
            categoryId: isset($data['categoryId']) ? (int) $data['categoryId'] : null,
        );
    }
}