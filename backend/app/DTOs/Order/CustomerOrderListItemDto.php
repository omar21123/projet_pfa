<?php
// app/DTOs/Order/CustomerOrderListItemDto.php

namespace App\DTOs\Order;

class CustomerOrderListItemDto
{
    public function __construct(
        public readonly int $orderId,
        public readonly string $orderNumber,
        public readonly string $statusCode,
        public readonly string $statusName,
        public readonly float $subtotal,
        public readonly float $shippingFee,
        public readonly float $discount,
        public readonly float $tax,
        public readonly float $total,
        public readonly string $currency,
        public readonly int $totalItems,
        public readonly int $totalVendors,
        public readonly ?string $orderedAt,
        public readonly ?string $updatedAt,
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            orderId: (int) $row->OrderID,
            orderNumber: $row->OrderNumber,
            statusCode: $row->StatusCode,
            statusName: $row->StatusName,
            subtotal: (float) $row->Subtotal,
            shippingFee: (float) $row->ShippingFee,
            discount: (float) $row->Discount,
            tax: (float) $row->Tax,
            total: (float) $row->Total,
            currency: $row->Currency,
            totalItems: (int) $row->TotalItems,
            totalVendors: (int) $row->TotalVendors,
            orderedAt: $row->OrderedAt,
            updatedAt: $row->UpdatedAt,
        );
    }

    public function toArray(): array
    {
        return [
            'order_id'      => $this->orderId,
            'order_number'  => $this->orderNumber,
            'status_code'   => $this->statusCode,
            'status_name'   => $this->statusName,
            'subtotal'      => $this->subtotal,
            'shipping_fee'  => $this->shippingFee,
            'discount'      => $this->discount,
            'tax'           => $this->tax,
            'total'         => $this->total,
            'currency'      => $this->currency,
            'total_items'   => $this->totalItems,
            'total_vendors' => $this->totalVendors,
            'ordered_at'    => $this->orderedAt,
            'updated_at'    => $this->updatedAt,
        ];
    }
}