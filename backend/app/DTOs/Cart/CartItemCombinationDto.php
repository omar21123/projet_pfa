<?php
// App\DTOs\Cart\CartItemCombinationDto
namespace App\DTOs\Cart;

class CartItemCombinationDto
{
    public function __construct(
        public readonly int $combinationId,
        public readonly ?string $sku,
        public readonly string $combinationName,
        public readonly float $combinationPrice,
        public readonly ?float $compareAtPrice,
        public readonly int $combinationStock,
        public readonly ?string $combinationImage,
        public readonly bool $isDefault,
        public readonly string $configurationName,
        public readonly string $configOptionName,
    ) {}

    public function toArray(): array
    {
        return [
            'CombinationID'     => $this->combinationId,
            'SKU'               => $this->sku,
            'CombinationName'   => $this->combinationName,
            'CombinationPrice'  => $this->combinationPrice,
            'CompareAtPrice'    => $this->compareAtPrice,
            'CombinationStock'  => $this->combinationStock,
            'CombinationImage'  => $this->combinationImage,
            'IsDefault'         => $this->isDefault,
            'ConfigurationName' => $this->configurationName,
            'ConfingOptionName' => $this->configOptionName,
        ];
    }
}