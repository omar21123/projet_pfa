<?php

namespace App\DTOs\Cart;

class AddCartItemDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $productId,
        public readonly bool $fromSearch,
        public readonly ?string $searchTerm,
        public readonly ?int $compositionId,
        public readonly float $unitPrice,
    ) {}

    public static function fromArray(array $data, string $userPublicId): self
    {
        return new self(
            userPublicId: $userPublicId,
            productId: (int) $data['productID'],
            fromSearch: filter_var($data['FromSearch'] ?? false, FILTER_VALIDATE_BOOLEAN),
            searchTerm: $data['SearchTerm'] ?? null,
            compositionId: isset($data['CompositionID']) ? (int) $data['CompositionID'] : null,
            unitPrice: (float) $data['UnitPrice'],
        );
    }
}