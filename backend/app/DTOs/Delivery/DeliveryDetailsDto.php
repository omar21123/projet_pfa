<?php
// app/DTOs/Delivery/DeliveryDetailsDto.php

namespace App\DTOs\Delivery;

class DeliveryDetailsDto
{
    public function __construct(
        public readonly int $deliveryId,
        public readonly int $orderId,
        public readonly int $vendorProfileId,
        public readonly ?string $storeName,
        public readonly string $statusCode,
        public readonly string $statusName,
        public readonly float $deliveryFee,
        public readonly ?string $notes,
        public readonly int $totalItems,

        public readonly AddressSummaryDto $addressFrom,
        public readonly AddressSummaryDto $addressTo,

        public readonly bool $isTaken,
        public readonly ?int $deliveryProfileId,
        public readonly ?string $livreurName,
        public readonly ?string $livreurPhone,
        public readonly ?string $livreurAvatarUrl,
        public readonly ?string $vehicleType,
        public readonly ?string $licensePlate,
        public readonly ?float $livreurRating,
        public readonly ?float $livreurCurrentLatitude,
        public readonly ?float $livreurCurrentLongitude,

        public readonly ?string $requestedAt,
        public readonly ?string $acceptedAt,
        public readonly ?string $pickedUpAt,
        public readonly ?string $deliveredAt,
        public readonly ?string $cancelledAt,
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            deliveryId: (int) $row->DeliveryID,
            orderId: (int) $row->OrderID,
            vendorProfileId: (int) $row->VendorProfileID,
            storeName: $row->StoreName,
            statusCode: $row->StatusCode,
            statusName: $row->StatusName,
            deliveryFee: (float) $row->DeliveryFee,
            notes: $row->Notes,
            totalItems: (int) $row->TotalItems,

            addressFrom: AddressSummaryDto::fromRow($row, 'From'),
            addressTo: AddressSummaryDto::fromRow($row, 'To'),

            isTaken: $row->DeliveryProfileID !== null,
            deliveryProfileId: $row->DeliveryProfileID !== null ? (int) $row->DeliveryProfileID : null,
            livreurName: $row->LivreurName,
            livreurPhone: $row->LivreurPhone,
            livreurAvatarUrl: $row->LivreurAvatarURL,
            vehicleType: $row->VehicleType,
            licensePlate: $row->LicensePlate,
            livreurRating: $row->LivreurRating !== null ? (float) $row->LivreurRating : null,
            livreurCurrentLatitude: $row->CurrentLatitude !== null ? (float) $row->CurrentLatitude : null,
            livreurCurrentLongitude: $row->CurrentLongitude !== null ? (float) $row->CurrentLongitude : null,

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
            'order_id'          => $this->orderId,
            'vendor_profile_id' => $this->vendorProfileId,
            'store_name'        => $this->storeName,
            'status_code'       => $this->statusCode,
            'status_name'       => $this->statusName,
            'delivery_fee'      => $this->deliveryFee,
            'notes'             => $this->notes,
            'total_items'       => $this->totalItems,
            'address_from'      => $this->addressFrom->toArray(),
            'address_to'        => $this->addressTo->toArray(),
            'is_taken'          => $this->isTaken,
            'livreur' => $this->isTaken ? [
                'delivery_profile_id' => $this->deliveryProfileId,
                'name'                => $this->livreurName,
                'phone'               => $this->livreurPhone,
                'avatar_url'          => $this->livreurAvatarUrl,
                'vehicle_type'        => $this->vehicleType,
                'license_plate'       => $this->licensePlate,
                'rating'              => $this->livreurRating,
                'current_latitude'    => $this->livreurCurrentLatitude,
                'current_longitude'   => $this->livreurCurrentLongitude,
            ] : null,
            'requested_at' => $this->requestedAt,
            'accepted_at'  => $this->acceptedAt,
            'picked_up_at' => $this->pickedUpAt,
            'delivered_at' => $this->deliveredAt,
            'cancelled_at' => $this->cancelledAt,
        ];
    }
}