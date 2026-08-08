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
        public readonly float $quantity,
        public readonly float $unitPrice,
    ) {}

    public static function fromArray(array $data, string $userPublicId): self
    {
        $quantity = isset($data['Quantity']) ? (float) $data['Quantity'] : 1.0;

        // Sécurité applicative : une quantité nulle ou négative retombe sur 1
        // (même règle de normalisation que côté procédure stockée SP_AddCartItem).
        if ($quantity <= 0) {
            $quantity = 1.0;
        }

        return new self(
            userPublicId: $userPublicId,
            productId: (int) $data['productID'],
            fromSearch: filter_var($data['FromSearch'] ?? false, FILTER_VALIDATE_BOOLEAN),
            searchTerm: $data['SearchTerm'] ?? null,
            compositionId: isset($data['CompositionID']) ? (int) $data['CompositionID'] : null,
            quantity: $quantity,
            unitPrice: (float) $data['UnitPrice'],
        );
    }
}