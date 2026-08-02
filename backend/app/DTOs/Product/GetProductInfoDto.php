<?php

namespace App\DTOs\Product;

class GetProductInfoDto
{
    public function __construct(
        public readonly int $productId,
        public readonly bool $fromSearch,
        public readonly ?string $searchTerm,
        public readonly ?string $userPublicId,
        public readonly ?string $ipAddress,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            productId: (int) $data['ProductID'],
            fromSearch: filter_var($data['FromSearch'] ?? false, FILTER_VALIDATE_BOOLEAN),
            searchTerm: $data['SearchTerm'] ?? null,
            userPublicId: $data['userPublicId'] ?? null,
            ipAddress: $data['ipAddress'] ?? null,
        );
    }
}