<?php
// app/DTOs/Order/CustomerOrderDeliveryDto.php

namespace App\DTOs\Order;

class CustomerOrderDeliveryDto
{
    /** @param DeliveryStatusHistoryItemDto[] $history */
    public function __construct(
        public readonly int $deliveryId,
        public readonly int $vendorProfileId,
        public readonly ?string $storeName,
        public readonly string $statusCode,
        public readonly string $statusName,
        public readonly float $deliveryFee,
        public readonly ?string $notes,

        public readonly int $fromAddressId,
        public readonly ?string $fromAddressLine1,
        public readonly ?string $fromCity,
        public readonly ?string $fromRegion,
        public readonly ?string $fromCountry,
        public readonly ?float $fromLatitude,
        public readonly ?float $fromLongitude,

        public readonly int $toAddressId,
        public readonly ?string $toAddressLine1,
        public readonly ?string $toCity,
        public readonly ?string $toRegion,
        public readonly ?string $toCountry,
        public readonly ?float $toLatitude,
        public readonly ?float $toLongitude,

        public readonly bool $isTaken,
        public readonly ?int $deliveryProfileId,
        public readonly ?string $livreurName,
        public readonly ?string $livreurPhone,
        public readonly ?string $livreurAvatarUrl,
        public readonly ?string $vehicleType,
        public readonly ?string $licensePlate,
        public readonly ?float $livreurRating,
        public readonly ?float $livreurLatitude,
        public readonly ?float $livreurLongitude,

        public readonly ?string $requestedAt,
        public readonly ?string $acceptedAt,
        public readonly ?string $pickedUpAt,
        public readonly ?string $deliveredAt,
        public readonly ?string $cancelledAt,

        public array $history = [],
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            deliveryId: (int) $row->DeliveryID,
            vendorProfileId: (int) $row->VendorProfileID,
            storeName: $row->StoreName,
            statusCode: $row->StatusCode,
            statusName: $row->StatusName,
            deliveryFee: (float) $row->DeliveryFee,
            notes: $row->Notes,

            fromAddressId: (int) $row->FromAddressID,
            fromAddressLine1: $row->FromAddressLine1,
            fromCity: $row->FromCity,
            fromRegion: $row->FromRegion,
            fromCountry: $row->FromCountry,
            fromLatitude: $row->FromLatitude !== null ? (float) $row->FromLatitude : null,
            fromLongitude: $row->FromLongitude !== null ? (float) $row->FromLongitude : null,

            toAddressId: (int) $row->ToAddressID,
            toAddressLine1: $row->ToAddressLine1,
            toCity: $row->ToCity,
            toRegion: $row->ToRegion,
            toCountry: $row->ToCountry,
            toLatitude: $row->ToLatitude !== null ? (float) $row->ToLatitude : null,
            toLongitude: $row->ToLongitude !== null ? (float) $row->ToLongitude : null,

            isTaken: $row->DeliveryProfileID !== null,
            deliveryProfileId: $row->DeliveryProfileID !== null ? (int) $row->DeliveryProfileID : null,
            livreurName: $row->LivreurName,
            livreurPhone: $row->LivreurPhone,
            livreurAvatarUrl: $row->LivreurAvatarURL,
            vehicleType: $row->VehicleType,
            licensePlate: $row->LicensePlate,
            livreurRating: $row->LivreurRating !== null ? (float) $row->LivreurRating : null,
            livreurLatitude: $row->LivreurLatitude !== null ? (float) $row->LivreurLatitude : null,
            livreurLongitude: $row->LivreurLongitude !== null ? (float) $row->LivreurLongitude : null,

            requestedAt: $row->RequestedAt,
            acceptedAt: $row->AcceptedAt,
            pickedUpAt: $row->PickedUpAt,
            deliveredAt: $row->DeliveredAt,
            cancelledAt: $row->CancelledAt,
        );
    }

    public function toArray(): array
    {
        return [
            'delivery_id'       => $this->deliveryId,
            'vendor_profile_id' => $this->vendorProfileId,
            'store_name'        => $this->storeName,
            'status_code'       => $this->statusCode,
            'status_name'       => $this->statusName,
            'delivery_fee'      => $this->deliveryFee,
            'notes'             => $this->notes,
            'address_from' => [
                'address_id' => $this->fromAddressId,
                'address_line1' => $this->fromAddressLine1,
                'city'    => $this->fromCity,
                'region'  => $this->fromRegion,
                'country' => $this->fromCountry,
                'latitude'  => $this->fromLatitude,
                'longitude' => $this->fromLongitude,
            ],
            'address_to' => [
                'address_id' => $this->toAddressId,
                'address_line1' => $this->toAddressLine1,
                'city'    => $this->toCity,
                'region'  => $this->toRegion,
                'country' => $this->toCountry,
                'latitude'  => $this->toLatitude,
                'longitude' => $this->toLongitude,
            ],
            'is_taken' => $this->isTaken,
            'livreur' => $this->isTaken ? [
                'delivery_profile_id' => $this->deliveryProfileId,
                'name'          => $this->livreurName,
                'phone'         => $this->livreurPhone,
                'avatar_url'    => $this->livreurAvatarUrl,
                'vehicle_type'  => $this->vehicleType,
                'license_plate' => $this->licensePlate,
                'rating'        => $this->livreurRating,
                'current_latitude'  => $this->livreurLatitude,
                'current_longitude' => $this->livreurLongitude,
            ] : null,
            'requested_at' => $this->requestedAt,
            'accepted_at'  => $this->acceptedAt,
            'picked_up_at' => $this->pickedUpAt,
            'delivered_at' => $this->deliveredAt,
            'cancelled_at' => $this->cancelledAt,
            'history' => array_map(fn($h) => $h->toArray(), $this->history),
        ];
    }
}