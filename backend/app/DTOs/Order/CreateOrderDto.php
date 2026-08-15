<?php
// app/DTOs/Order/CreateOrderDto.php

namespace App\DTOs\Order;

class CreateOrderDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $addressId,
        public readonly int $paymentMethodId,
        public readonly float $subtotal,
        public readonly ?string $notes = null,
    ) {
    }
}