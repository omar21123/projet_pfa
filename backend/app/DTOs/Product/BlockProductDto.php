<?php

namespace App\DTOs\Product;

class BlockProductDto
{
    public function __construct(
        public readonly int $productId,
        public readonly int $blockedBy,
        public readonly ?string $notes,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            productId: (int) $data['ProductID'],
            blockedBy: (int) $data['BlockedBy'],
            notes: $data['BlockedNotes'] ?? null,
        );
    }
}