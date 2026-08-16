<?php
// app/DTOs/Order/DeliveryStatusHistoryItemDto.php

namespace App\DTOs\Order;

class DeliveryStatusHistoryItemDto
{
    public function __construct(
        public readonly string $statusCode,
        public readonly string $statusName,
        public readonly ?float $latitude,
        public readonly ?float $longitude,
        public readonly ?string $changedAt,
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            statusCode: $row->StatusCode,
            statusName: $row->StatusName,
            latitude: $row->Latitude !== null ? (float) $row->Latitude : null,
            longitude: $row->Longitude !== null ? (float) $row->Longitude : null,
            changedAt: $row->ChangedAt,
        );
    }

    public function toArray(): array
    {
        return [
            'status_code' => $this->statusCode,
            'status_name' => $this->statusName,
            'latitude'    => $this->latitude,
            'longitude'   => $this->longitude,
            'changed_at'  => $this->changedAt,
        ];
    }
}