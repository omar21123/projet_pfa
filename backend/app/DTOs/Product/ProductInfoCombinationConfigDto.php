<?php
// App\DTOs\Product\ProductInfoCombinationConfigDto
namespace App\DTOs\Product;

class ProductInfoCombinationConfigDto
{
    public function __construct(
        public readonly int $configId,
        public readonly int $optionId,
    ) {}

    public function toArray(): array
    {
        return [
            'ConfigID' => $this->configId,
            'OptionID' => $this->optionId,
        ];
    }
}