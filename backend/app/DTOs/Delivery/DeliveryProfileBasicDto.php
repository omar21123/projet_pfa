<?php
// app/DTOs/Delivery/DeliveryProfileBasicDto.php

namespace App\DTOs\Delivery;

class DeliveryProfileBasicDto
{
    public function __construct(
        public readonly int $deliveryProfileId,
        public readonly int $userId,
        public readonly bool $isApproved,
        public readonly bool $isSuspended,
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            deliveryProfileId: (int) $row->DeliveryProfileID,
            userId: (int) $row->UserID,
            isApproved: (bool) $row->IsApproved,
            isSuspended: (bool) $row->IsSuspended,
        );
    }
}