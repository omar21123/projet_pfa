<?php

namespace App\DTOs\Product;

class CreateProductCombinationDto
{
    /** @var CreateProductCombinationOptionDto[] */
    public readonly array $options;

    public function __construct(
        public readonly ?string $sku,
        public readonly float $price,
        public readonly ?float $compareAtPrice,
        public readonly int $stock,
        public readonly ?string $imagePath,
        public readonly bool $isDefault,
        array $options = [],
    ) {
        $this->options = $options;
    }

    public static function fromArray(array $data): self
    {
        $options = array_map(
            fn(array $o) => CreateProductCombinationOptionDto::fromArray($o),
            $data['Options'] ?? []
        );

        return new self(
            sku: $data['SKU'] ?? null,
            price: (float) $data['Price'],
            compareAtPrice: isset($data['CompareAtPrice']) ? (float) $data['CompareAtPrice'] : null,
            stock: (int) ($data['Stock'] ?? 0),
            imagePath: $data['ImagePath'] ?? null, // set after file upload in controller
            isDefault: (bool) ($data['IsDefault'] ?? false),
            options: $options,
        );
    }
}