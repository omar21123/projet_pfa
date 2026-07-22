<?php

namespace App\DTOs\Product;

class ValidateProductDto
{
    public function __construct(
        public readonly int $productId,
        public readonly int $validatorId,
        public readonly ?string $notes,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            productId: (int) $data['ProductID'],
            validatorId: (int) $data['ValidatorID'],
            notes: $data['ValidationNotes'] ?? null,
        );
    }
}