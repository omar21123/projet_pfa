<?php
// app/DTOs/Delivery/SuspendDeliveryProfileDto.php

namespace App\DTOs\Delivery;

class SuspendDeliveryProfileDto
{
    public function __construct(
        public readonly int $deliveryProfileId,
        public readonly int $suspendedBy,
        public readonly ?string $reason,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            deliveryProfileId: (int) $data['DeliveryProfileID'],
            suspendedBy: (int) $data['SuspendedBy'],
            reason: $data['Reason'] ?? null,
        );
    }
}