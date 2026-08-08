<?php

namespace App\DTOs\Geo;

class IpLocationDto
{
    public function __construct(
        public readonly string $ip,
        public readonly ?string $countryCode,
        public readonly ?string $region,
        public readonly ?string $city,
    ) {}

    public static function fromApiResponse(array $data): self
    {
        return new self(
            ip: $data['ip'],
            countryCode: $data['country_code'] ?? null,
            region: $data['region'] ?? null,
            city: $data['city'] ?? null,
        );
    }
}