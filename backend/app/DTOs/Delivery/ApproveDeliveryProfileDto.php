<?php
// app/DTOs/Delivery/ApproveDeliveryProfileDto.php

namespace App\DTOs\Delivery;

class ApproveDeliveryProfileDto
{
    public function __construct(
        public readonly int $deliveryProfileId,
        public readonly int $approvedBy,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            deliveryProfileId: (int) $data['DeliveryProfileID'],
            approvedBy: (int) $data['ApprovedBy'],
        );
    }
}