<?php

namespace App\DTOs\Product;

class ProductInfoCombinationConfigDto
{
    public function __construct(
        public readonly int $configId,
        public readonly int $optionId,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            configId: (int) $row->ProductsConfigAttributeID,
            optionId: (int) $row->OptionID,
        );
    }

    public function toArray(): array
    {
        return [
            'ConfigID' => $this->configId,
            'OptionID' => $this->optionId,
        ];
    }
}