<?php
// app/DTOs/Delivery/AddOrderItemToDeliveryDto.php

namespace App\DTOs\Delivery;

class AddOrderItemToDeliveryDto
{
    public function __construct(
        public readonly int $productId,
        public readonly int $orderId,
        public readonly int $orderItemId,
        public readonly int $addressToId,
        public readonly ?string $notes = null,
        public readonly ?string $userPublicId = null,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            productId: $data['ProductID'],
            orderId: $data['OrderID'],
            orderItemId: $data['OrderItemID'],
            addressToId: $data['AddressToID'],
            notes: $data['Notes'] ?? null,
            userPublicId: $data['userPublicId'] ?? null,
        );
    }
}