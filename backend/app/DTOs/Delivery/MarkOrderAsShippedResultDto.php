<?php
// app/DTOs/Delivery/MarkOrderAsShippedResultDto.php

namespace App\DTOs\Delivery;

class MarkOrderAsShippedResultDto
{
    public function __construct(
        public readonly bool $orderFullyShipped,
        public readonly string $message,
    ) {
    }

    public function toArray(): array
    {
        return [
            'order_fully_shipped' => $this->orderFullyShipped,
            'message'              => $this->message,
        ];
    }
}