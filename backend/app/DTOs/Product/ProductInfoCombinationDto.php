<?php

namespace App\DTOs\Product;

class ProductInfoCombinationDto
{
    public function __construct(
        public readonly int $combinationId,
        public readonly ?string $sku,
        public readonly float $combinationPrice,
        public readonly ?float $compareAtPrice,
        public readonly int $combinationStock,
        public readonly ?string $combinationImage,
        public readonly bool $isDefault,
        public  ?ProductInfoCombinationConfigDto $configs = null,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            combinationId: (int) $row->CombinationID,
            sku: $row->SKU,
            combinationPrice: (float) $row->Price,
            compareAtPrice: $row->CompareAtPrice !== null ? (float) $row->CompareAtPrice : null,
            combinationStock: (int) $row->Stock,
            combinationImage: $row->ImagePath,
            isDefault: (bool) $row->IsDefault,
            // configs non chargées ici — à peupler séparément (cf. point "Configs"
            // singulier vs tableau resté à trancher).
        );
    }

    public function toArray(): array
    {
        return [
            'CombinationID'    => $this->combinationId,
            'SKU'              => $this->sku,
            'CombinationPrice' => $this->combinationPrice,
            'CompareAtPrice'   => $this->compareAtPrice,
            'CombinationStock' => $this->combinationStock,
            'CombinationImage' => $this->combinationImage,
            'IsDefault'        => $this->isDefault,
            'Configs'          => $this->configs?->toArray(),
        ];
    }
}