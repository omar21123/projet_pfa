<?php

namespace App\DTOs\Product;

class RefuseProductDto
{
    public function __construct(
        public readonly int $productId,
        public readonly int $refusedBy,
        public readonly string $notes,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            productId: (int) $data['ProductID'],
            refusedBy: (int) $data['RefusedBy'],
            notes: $data['RefuseNotes'],
        );
    }
}