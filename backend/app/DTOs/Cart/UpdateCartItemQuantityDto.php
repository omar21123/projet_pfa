<?php

namespace App\DTOs\Cart;

class UpdateCartItemQuantityDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $cartItemId,
        public readonly float $quantity,
    ) {}

    public static function fromArray(array $data, string $userPublicId): self
    {
        return new self(
            userPublicId: $userPublicId,
            cartItemId: (int) $data['CartItemID'],
            quantity: (float) $data['Quantity'],
        );
    }
}