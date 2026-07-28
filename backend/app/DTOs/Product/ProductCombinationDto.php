<?php

namespace App\DTOs\Product;

class ProductCombinationDto
{
    /**
     * @param ProductCombinationOptionDto[] $options
     */
    public function __construct(
        public readonly int $combinationId,
        public readonly ?string $sku,
        public readonly float $price,
        public readonly int $stock,
        public readonly ?string $imagePath,
        public readonly bool $isDefault,
        public readonly array $options,
    ) {}

    /**
     * Groups the flat rowset returned by SP_GetProductCombinationsForVendor
     * (one row per combination/option pair) into one DTO per CombinationID.
     *
     * @param object[] $rows
     * @return ProductCombinationDto[]
     */
    public static function fromRows(array $rows): array
    {
        $grouped = [];

        foreach ($rows as $row) {
            $id = (int) $row->CombinationID;

            if (!isset($grouped[$id])) {
                $grouped[$id] = [
                    'combinationId' => $id,
                    'sku'           => $row->SKU,
                    'price'         => (float) $row->Price,
                    'stock'         => (int) $row->Stock,
                    'imagePath'     => $row->ImagePath,
                    'isDefault'     => (bool) $row->IsDefault,
                    'options'       => [],
                ];
            }

            $grouped[$id]['options'][] = ProductCombinationOptionDto::fromRow($row);
        }

        return array_values(array_map(
            fn(array $g) => new self(
                combinationId: $g['combinationId'],
                sku: $g['sku'],
                price: $g['price'],
                stock: $g['stock'],
                imagePath: $g['imagePath'],
                isDefault: $g['isDefault'],
                options: $g['options'],
            ),
            $grouped
        ));
    }
}