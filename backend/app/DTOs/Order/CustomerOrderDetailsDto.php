<?php
// app/DTOs/Order/CustomerOrderDetailsDto.php

namespace App\DTOs\Order;

class CustomerOrderDetailsDto
{
    /**
     * @param CustomerOrderItemDto[] $items
     * @param CustomerOrderDeliveryDto[] $deliveries
     */
    public function __construct(
        public readonly int $orderId,
        public readonly string $orderNumber,
        public readonly string $orderStatusCode,
        public readonly string $orderStatusName,
        public readonly float $subtotal,
        public readonly float $shippingFee,
        public readonly float $discount,
        public readonly float $tax,
        public readonly float $total,
        public readonly string $currency,
        public readonly ?string $notes,
        public readonly ?string $orderedAt,
        public readonly ?string $updatedAt,

        public readonly array $billingAddress,
        public readonly array $shippingAddress,

        public  array $items,
        public  array $deliveries,
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            orderId: (int) $row->OrderID,
            orderNumber: $row->OrderNumber,
            orderStatusCode: $row->OrderStatusCode,
            orderStatusName: $row->OrderStatusName,
            subtotal: (float) $row->Subtotal,
            shippingFee: (float) $row->ShippingFee,
            discount: (float) $row->Discount,
            tax: (float) $row->Tax,
            total: (float) $row->Total,
            currency: $row->Currency,
            notes: $row->Notes,
            orderedAt: $row->OrderedAt,
            updatedAt: $row->UpdatedAt,

            billingAddress: [
                'address_id'     => (int) $row->BillingAddressID,
                'address_line1'  => $row->BillingAddressLine1,
                'city'           => $row->BillingCity,
                'region'         => $row->BillingRegion,
                'country'        => $row->BillingCountry,
                'latitude'       => $row->BillingLatitude !== null ? (float) $row->BillingLatitude : null,
                'longitude'      => $row->BillingLongitude !== null ? (float) $row->BillingLongitude : null,
            ],
            shippingAddress: [
                'address_id'     => (int) $row->ShippingAddressID,
                'address_line1'  => $row->ShippingAddressLine1,
                'city'           => $row->ShippingCity,
                'region'         => $row->ShippingRegion,
                'country'        => $row->ShippingCountry,
                'latitude'       => $row->ShippingLatitude !== null ? (float) $row->ShippingLatitude : null,
                'longitude'      => $row->ShippingLongitude !== null ? (float) $row->ShippingLongitude : null,
            ],

            items: [],
            deliveries: [],
        );
    }

    public function toArray(): array
    {
        return [
            'order_id'          => $this->orderId,
            'order_number'      => $this->orderNumber,
            'status_code'       => $this->orderStatusCode,
            'status_name'       => $this->orderStatusName,
            'subtotal'          => $this->subtotal,
            'shipping_fee'      => $this->shippingFee,
            'discount'          => $this->discount,
            'tax'               => $this->tax,
            'total'             => $this->total,
            'currency'          => $this->currency,
            'notes'             => $this->notes,
            'ordered_at'        => $this->orderedAt,
            'updated_at'        => $this->updatedAt,
            'billing_address'   => $this->billingAddress,
            'shipping_address'  => $this->shippingAddress,
            'items'             => array_map(fn($i) => $i->toArray(), $this->items),
            'deliveries'        => array_map(fn($d) => $d->toArray(), $this->deliveries),
        ];
    }
}