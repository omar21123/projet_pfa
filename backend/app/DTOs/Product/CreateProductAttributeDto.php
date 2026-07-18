<?php

namespace App\DTOs\Product;

use App\DTOs\ProductsConfigAttribute\CreateProductsConfigOptionDto;

class CreateProductAttributeDto
{
    /** @var CreateProductsConfigOptionDto[] */
    public readonly array $configOptions;

    public function __construct(
        public readonly string $configName,
        array $configOptions = [],
    ) {
        $this->configOptions = $configOptions;
    }

    public static function fromArray(array $data): self
    {
        $configOptions = array_map(
            fn(array $opt) => CreateProductsConfigOptionDto::fromArray($opt),
            $data['ConfigOptions'] ?? []
        );

        return new self(
            configName: $data['ConfigName'],
            configOptions: $configOptions,
        );
    }
}