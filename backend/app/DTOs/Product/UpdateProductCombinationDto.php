<?php

namespace App\DTOs\Product;

class UpdateProductCombinationDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $combinationId,
        public readonly ?string $sku,
        public readonly float $price,
        public readonly ?float $compareAtPrice,
        public readonly int $stock,
        public readonly ?string $imagePath,
        public readonly bool $isDefault,
        public readonly bool $isActive,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['UserPublicID'],
            combinationId: (int) $data['CombinationID'],
            sku: $data['SKU'] ?? null,
            price: (float) $data['Price'],
            compareAtPrice: isset($data['CompareAtPrice']) ? (float) $data['CompareAtPrice'] : null,
            stock: (int) $data['Stock'],
            imagePath: $data['ImagePath'] ?? null,
            isDefault: (bool) ($data['IsDefault'] ?? false),
            isActive: (bool) ($data['IsActive'] ?? true),
        );
    }
}