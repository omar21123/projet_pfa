<?php
// app/DTOs/Delivery/CreateDeliveryFromOrderDto.php

namespace App\DTOs\Delivery;

class CreateDeliveryFromOrderDto
{
    public function __construct(
        public readonly int $orderId,
        public readonly int $addressFromId,
        public readonly int $addressToId,
        public readonly float $deliveryFee,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            orderId: $data['OrderID'],
            addressFromId: $data['AddressFromID'],
            addressToId: $data['AddressToID'],
            deliveryFee: $data['DeliveryFee'],
        );
    }
}