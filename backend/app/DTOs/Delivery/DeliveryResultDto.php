<?php
// app/DTOs/Delivery/DeliveryResultDto.php

namespace App\DTOs\Delivery;

class DeliveryResultDto
{
    public function __construct(
        public readonly int $deliveryId,
        public readonly string $message,
    ) {
    }

    public static function fromOutput(object $row): self
    {
        return new self(
            deliveryId: (int) $row->deliveryId,
            message: (string) $row->message,
        );
    }

    public function toArray(): array
    {
        return [
            'DeliveryID' => $this->deliveryId,
            'Message'    => $this->message,
        ];
    }
}