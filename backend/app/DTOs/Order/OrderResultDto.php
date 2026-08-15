<?php
// app/DTOs/Order/OrderResultDto.php

namespace App\DTOs\Order;

class OrderResultDto
{
    public function __construct(
        public readonly int $orderId,
        public readonly string $orderNumber,
        public readonly string $message,
    ) {
    }

    public static function fromOutput(object $row): self
    {
        return new self(
            orderId: (int) $row->orderId,
            orderNumber: (string) $row->orderNumber,
            message: (string) $row->message,
        );
    }
}