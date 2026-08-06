<?php
// App\DTOs\Product\Stats\IncrementRegionalProductStatDto
namespace App\DTOs\Product\Stats;

class IncrementRegionalProductStatDto
{
    public function __construct(
        public readonly int $productId,
        public readonly string $countryCode,
        public readonly ?string $region,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            productId: (int) $data['ProductID'],
            countryCode: strtoupper($data['CountryCode']),
            region: $data['Region'] ?? null,
        );
    }
}