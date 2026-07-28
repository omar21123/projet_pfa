<?php

namespace App\DTOs\Product;

class ProductCombinationOptionDto
{
    public function __construct(
        public readonly string $configName,
        public readonly string $optionName,
        public readonly string $optionValue,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            configName: $row->ConfigName,
            optionName: $row->OptionName,
            optionValue: $row->OptionValue,
        );
    }
}