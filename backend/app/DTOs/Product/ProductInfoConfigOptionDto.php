<?php
// App\DTOs\Product\ProductInfoConfigOptionDto
namespace App\DTOs\Product;

class ProductInfoConfigOptionDto
{
    public function __construct(
        public readonly int $optionId,
        public readonly string $optionLabel,
        public readonly string $optionValue,
        public readonly bool $isDefault,
    ) {}

    public function toArray(): array
    {
        return [
            'OptionID'    => $this->optionId,
            'OptionLabel' => $this->optionLabel,
            'OptionValue' => $this->optionValue,
            'isDefault'   => $this->isDefault,
        ];
    }
}