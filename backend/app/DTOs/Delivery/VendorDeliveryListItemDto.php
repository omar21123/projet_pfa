<?php
// app/DTOs/Delivery/VendorDeliveryListItemDto.php

namespace App\DTOs\Delivery;

class VendorDeliveryListItemDto
{
    public function __construct(
        public readonly int $deliveryId,
        public readonly int $orderId,
        public readonly string $statusCode,
        public readonly string $statusName,
        public readonly bool $isTaken,
        public readonly ?int $deliveryProfileId,
        public readonly ?string $livreurName,
        public readonly ?string $livreurPhone,
        public readonly float $deliveryFee,
        public readonly int $totalItems,
        public readonly ?string $toCity,
        public readonly ?string $toRegion,
        public readonly ?string $requestedAt,
        public readonly ?string $acceptedAt,
        public readonly ?string $deliveredAt,
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            deliveryId: (int) $row->DeliveryID,
            orderId: (int) $row->OrderID,
            statusCode: $row->StatusCode,
            statusName: $row->StatusName,
            isTaken: (bool) $row->IsTaken,
            deliveryProfileId: $row->DeliveryProfileID !== null ? (int) $row->DeliveryProfileID : null,
            livreurName: $row->LivreurName,
            livreurPhone: $row->LivreurPhone,
            deliveryFee: (float) $row->DeliveryFee,
            totalItems: (int) $row->TotalItems,
            toCity: $row->ToCity,
            toRegion: $row->ToRegion,
            requestedAt: $row->RequestedAt,
            acceptedAt: $row->AcceptedAt,
            deliveredAt: $row->DeliveredAt,
        );
    }

    public function toArray(): array
    {
        return [
            'delivery_id'  => $this->deliveryId,
            'order_id'     => $this->orderId,
            'status_code'  => $this->statusCode,
            'status_name'  => $this->statusName,
            'is_taken'     => $this->isTaken,
            'livreur' => $this->isTaken ? [
                'delivery_profile_id' => $this->deliveryProfileId,
                'name'                => $this->livreurName,
                'phone'               => $this->livreurPhone,
            ] : null,
            'delivery_fee' => $this->deliveryFee,
            'total_items'  => $this->totalItems,
            'dropoff' => [
                'city'   => $this->toCity,
                'region' => $this->toRegion,
            ],
            'requested_at' => $this->requestedAt,
            'accepted_at'  => $this->acceptedAt,
            'delivered_at' => $this->deliveredAt,
        ];
    }
}