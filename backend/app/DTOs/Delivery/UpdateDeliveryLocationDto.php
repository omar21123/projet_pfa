<?php
// app/DTOs/Delivery/UpdateDeliveryLocationDto.php

namespace App\DTOs\Delivery;

class UpdateDeliveryLocationDto
{
    public function __construct(
        public readonly int $deliveryProfileId,
        public readonly float $latitude,
        public readonly float $longitude,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            deliveryProfileId: (int) $data['DeliveryProfileID'],
            latitude: (float) $data['Latitude'],
            longitude: (float) $data['Longitude'],
        );
    }
}