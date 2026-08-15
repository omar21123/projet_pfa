<?php
// app/DTOs/Delivery/RecommendedDeliveryItemDto.php

namespace App\DTOs\Delivery;

class RecommendedDeliveryItemDto
{
    public function __construct(
        public readonly int $deliveryId,
        public readonly int $vendorProfileId,
        public readonly ?string $storeName,
        public readonly float $deliveryFee,
        public readonly ?string $requestedAt,
        public readonly int $totalItems,
        public readonly float $distanceKm,

        public readonly int $fromAddressId,
        public readonly ?string $fromAddressLine1,
        public readonly ?string $fromCity,
        public readonly ?string $fromRegion,
        public readonly ?float $fromLatitude,
        public readonly ?float $fromLongitude,

        public readonly int $toAddressId,
        public readonly ?string $toCity,
        public readonly ?string $toRegion,
    ) {
    }

    public static function fromRow(object $row): self
    {
        $values = [];
        foreach ((array) $row as $key => $value) {
            $values[strtolower($key)] = $value;
        }

        return new self(
            deliveryId: (int) ($values['deliveryid'] ?? $values['delivery_id'] ?? 0),
            vendorProfileId: (int) ($values['vendorprofileid'] ?? $values['vendor_profile_id'] ?? 0),
            storeName: $values['storename'] ?? $values['store_name'] ?? null,
            deliveryFee: (float) ($values['deliveryfee'] ?? $values['delivery_fee'] ?? 0),
            requestedAt: $values['requestedat'] ?? $values['requested_at'] ?? null,
            totalItems: (int) ($values['totalitems'] ?? $values['total_items'] ?? 0),
            distanceKm: (float) ($values['distancekm'] ?? $values['distance_km'] ?? 0),

            fromAddressId: (int) ($values['fromaddressid'] ?? $values['from_address_id'] ?? 0),
            fromAddressLine1: $values['fromaddressline1'] ?? $values['from_address_line1'] ?? null,
            fromCity: $values['fromcity'] ?? $values['from_city'] ?? null,
            fromRegion: $values['fromregion'] ?? $values['from_region'] ?? null,
            fromLatitude: isset($values['fromlatitude']) ? (float) $values['fromlatitude'] : (isset($values['from_latitude']) ? (float) $values['from_latitude'] : null),
            fromLongitude: isset($values['fromlongitude']) ? (float) $values['fromlongitude'] : (isset($values['from_longitude']) ? (float) $values['from_longitude'] : null),

            toAddressId: (int) ($values['toaddressid'] ?? $values['to_address_id'] ?? 0),
            toCity: $values['tocity'] ?? $values['to_city'] ?? null,
            toRegion: $values['toregion'] ?? $values['to_region'] ?? null,
        );
    }

    public function toArray(): array
    {
        return [
            'delivery_id'       => $this->deliveryId,
            'vendor_profile_id' => $this->vendorProfileId,
            'store_name'        => $this->storeName,
            'delivery_fee'      => $this->deliveryFee,
            'requested_at'      => $this->requestedAt,
            'total_items'       => $this->totalItems,
            'distance_km'       => $this->distanceKm,
            'pickup' => [
                'address_id'    => $this->fromAddressId,
                'address_line1' => $this->fromAddressLine1,
                'city'          => $this->fromCity,
                'region'        => $this->fromRegion,
                'latitude'      => $this->fromLatitude,
                'longitude'     => $this->fromLongitude,
            ],
            'dropoff' => [
                'address_id' => $this->toAddressId,
                'city'       => $this->toCity,
                'region'     => $this->toRegion,
            ],
        ];
    }
}