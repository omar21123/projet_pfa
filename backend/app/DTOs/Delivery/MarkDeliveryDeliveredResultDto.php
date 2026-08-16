<?php
// app/DTOs/Delivery/MarkDeliveryDeliveredResultDto.php

namespace App\DTOs\Delivery;

class MarkDeliveryDeliveredResultDto
{
    public function __construct(
        public readonly string $message,
    ) {
    }

    public function toArray(): array
    {
        return [
            'message' => $this->message,
        ];
    }
}