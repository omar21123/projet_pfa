<?php
// app/DTOs/Delivery/GetRecommendedDeliveriesDto.php

namespace App\DTOs\Delivery;

class GetRecommendedDeliveriesDto
{
    public function __construct(
        public readonly int $deliveryProfileId,
        public readonly ?float $maxDistanceKm,
        public readonly int $page,
        public readonly int $perPage,
    ) {
    }

    public static function fromRequest(array $validated, int $deliveryProfileId): self
    {
        return new self(
            deliveryProfileId: $deliveryProfileId,
            maxDistanceKm: isset($validated['max_distance_km']) ? (float) $validated['max_distance_km'] : null,
            page: (int) ($validated['page'] ?? 1),
            perPage: (int) ($validated['per_page'] ?? 20),
        );
    }
}