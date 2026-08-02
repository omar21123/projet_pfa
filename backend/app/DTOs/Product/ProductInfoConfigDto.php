<?php
// App\DTOs\Product\ProductInfoConfigDto
namespace App\DTOs\Product;

class ProductInfoConfigDto
{
    /** @param ProductInfoConfigOptionDto[] $options */
    public function __construct(
        public readonly int $configId,
        public readonly string $configName,
        public readonly array $options,
    ) {}

    public function toArray(): array
    {
        return [
            'ConfigID'   => $this->configId,
            'ConfigName' => $this->configName,
            'Options'    => array_map(fn($o) => $o->toArray(), $this->options),
        ];
    }
}