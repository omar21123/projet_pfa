<?php

namespace App\DTOs\Product;

class CreateProductCombinationOptionDto
{
    public function __construct(
        public readonly string $configName,
        public readonly string $optionName,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            configName: $data['ConfigName'],
            optionName: $data['OptionName'],
        );
    }
}