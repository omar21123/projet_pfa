<?php
// app/DTOs/Order/CreateOrderFromCartDto.php

namespace App\DTOs\Order;

class CreateOrderFromCartDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $addressId,
        public readonly int $paymentMethodId,
        public readonly ?string $notes = null,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['UserPublicID'],
            addressId: $data['AddressID'],
            paymentMethodId: $data['PaymentMethodID'],
            notes: $data['Notes'] ?? null,
        );
    }
}