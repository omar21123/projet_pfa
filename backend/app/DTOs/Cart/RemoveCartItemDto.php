<?php

namespace App\DTOs\Cart;

class RemoveCartItemDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $productId,
        public readonly ?int $compositionId,
    ) {}

    public static function fromArray(array $data, string $userPublicId): self
    {
        return new self(
            userPublicId: $userPublicId,
            productId: (int) $data['productID'],
            compositionId: isset($data['CompositionID']) ? (int) $data['CompositionID'] : null,
        );
    }
}