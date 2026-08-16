<?php
// app/DTOs/Delivery/DeliveryHistoryItemDto.php

namespace App\DTOs\Delivery;

class DeliveryHistoryItemDto
{
    public function __construct(
        public readonly int $deliveryId,
        public readonly int $orderId,
        public readonly int $vendorProfileId,
        public readonly ?string $storeName,
        public readonly string $statusCode,
        public readonly string $statusName,
        public readonly float $deliveryFee,
        public readonly int $totalItems,

        public readonly ?string $fromCity,
        public readonly ?string $fromRegion,
        public readonly ?string $fromCountry,

        public readonly ?string $toCity,
        public readonly ?string $toRegion,
        public readonly ?string $toCountry,

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
            totalItems: (int) $row->TotalItems,

            fromCity: $row->FromCity,
            fromRegion: $row->FromRegion,
            fromCountry: $row->FromCountry,

            toCity: $row->ToCity,
            toRegion: $row->ToRegion,
            toCountry: $row->ToCountry,

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
            'total_items'       => $this->totalItems,
            'pickup' => [
                'city'    => $this->fromCity,
                'region'  => $this->fromRegion,
                'country' => $this->fromCountry,
            ],
            'dropoff' => [
                'city'    => $this->toCity,
                'region'  => $this->toRegion,
                'country' => $this->toCountry,
            ],
            'requested_at' => $this->requestedAt,
            'accepted_at'  => $this->acceptedAt,
            'picked_up_at' => $this->pickedUpAt,
            'delivered_at' => $this->deliveredAt,
            'cancelled_at' => $this->cancelledAt,
        ];
    }
}