<?php

namespace App\DTOs\Product;

class ProductInfoConfigDto
{
    /** @param ProductInfoConfigOptionDto[] $options */
    public function __construct(
        public readonly int $configId,
        public readonly string $configName,
        public readonly array $options,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            configId: (int) $row->ProductsConfigAttributeID,
            configName: $row->Name,
            options: [], // TODO: options non chargées ici, à faire dans un second temps
        );
    }

    public function toArray(): array
    {
        return [
            'ConfigID'   => $this->configId,
            'ConfigName' => $this->configName,
            'Options'    => array_map(fn($o) => $o->toArray(), $this->options),
        ];
    }
}