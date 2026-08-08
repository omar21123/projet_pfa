<?php

namespace App\DTOs\Product;

class LoadMoreProductsQueryDto
{
    public function __construct(
        public readonly ?string $userPublicId,
        public readonly int $pageNumber,
        public readonly int $pageSize,
        public readonly ?int $categoryId = null,
        public readonly ?string $ipAddress = null,      // SP_LoadMoreLastActivityProducts
        public readonly ?string $countryCode = null,     // SP_LoadMorePopularInYourRegion
        public readonly ?string $region = null,           // SP_LoadMorePopularInYourRegion
        public readonly ?int $daysBack = null,             // SP_LoadMoreNewProducts
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['userPublicId'] ?? null,
            pageNumber: (int) ($data['pageNumber'] ?? 1),
            pageSize: (int) ($data['pageSize'] ?? 20),
            categoryId: isset($data['categoryId']) ? (int) $data['categoryId'] : null,
            ipAddress: $data['ipAddress'] ?? null,
            countryCode: $data['countryCode'] ?? null,
            region: $data['region'] ?? null,
            daysBack: isset($data['daysBack']) ? (int) $data['daysBack'] : null,
        );
    }
}