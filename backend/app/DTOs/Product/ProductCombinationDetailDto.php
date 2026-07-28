<?php

namespace App\DTOs\Product;

class ProductCombinationDetailDto
{
    /**
     * @param ProductCombinationOptionDto[] $options
     */
    public function __construct(
        public readonly int $combinationId,
        public readonly int $productId,
        public readonly ?string $sku,
        public readonly float $price,
        public readonly ?float $compareAtPrice,
        public readonly int $stock,
        public readonly ?string $imagePath,
        public readonly bool $isDefault,
        public readonly bool $isActive,
        public readonly string $createdAt,
        public readonly string $updatedAt,
        public readonly array $options,
    ) {}

    public static function fromRow(object $row, array $options = []): self
    {
        return new self(
            combinationId: (int) $row->CombinationID,
            productId: (int) $row->ProductID,
            sku: $row->SKU,
            price: (float) $row->Price,
            compareAtPrice: $row->CompareAtPrice !== null ? (float) $row->CompareAtPrice : null,
            stock: (int) $row->Stock,
            imagePath: $row->ImagePath,
            isDefault: (bool) $row->IsDefault,
            isActive: (bool) $row->IsActive,
            createdAt: (string) $row->CreatedAt,
            updatedAt: (string) $row->UpdatedAt,
            options: array_map(fn($o) => ProductCombinationOptionDto::fromRow($o), $options),
        );
    }

    public function toArray(): array
    {
        return [
            'combination_id'   => $this->combinationId,
            'product_id'       => $this->productId,
            'sku'              => $this->sku,
            'price'            => $this->price,
            'compare_at_price' => $this->compareAtPrice,
            'stock'            => $this->stock,
            'image_path'       => $this->imagePath,
            'is_default'       => $this->isDefault,
            'is_active'        => $this->isActive,
            'created_at'       => $this->createdAt,
            'updated_at'       => $this->updatedAt,
            'options'          => array_map(fn($o) => [
                'config_name'  => $o->configName,
                'option_name'  => $o->optionName,
                'option_value' => $o->optionValue,
            ], $this->options),
        ];
    }
}