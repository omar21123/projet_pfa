<?php

namespace App\DTOs\ProductsConfigAttribute;

class CreateProductsConfigOptionDto
{
    public function __construct(
        public readonly string $name,
        public readonly bool $isDefault = false,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            name: $data['Name'],
            isDefault: isset($data['IsDefault']) ? (bool) $data['IsDefault'] : false,
        );
    }
}