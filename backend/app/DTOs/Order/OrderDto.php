<?php
// app/DTOs/Order/OrderDto.php

namespace App\DTOs\Order;

class OrderDto
{
    public function __construct(
        public readonly int $orderId,
        public readonly string $orderNumber,
        public readonly int $userId,
        public readonly int $billingAddressId,
        public readonly int $shippingAddressId,
        public readonly int $orderStatusId,
        public readonly int $paymentMethodId,
        public readonly float $subtotal,
        public readonly float $shippingFee,
        public readonly float $discount,
        public readonly float $tax,
        public readonly float $total,
        public readonly string $currency,
        public readonly ?string $notes,
        public readonly string $createdAt,
    ) {}
    // app/DTOs/Order/OrderDto.php — add this method
    public function toArray(): array
    {
        return [
            'order_id'            => $this->orderId,
            'order_number'        => $this->orderNumber,
            'user_id'             => $this->userId,
            'billing_address_id'  => $this->billingAddressId,
            'shipping_address_id' => $this->shippingAddressId,
            'order_status_id'     => $this->orderStatusId,
            'payment_method_id'   => $this->paymentMethodId,
            'subtotal'            => $this->subtotal,
            'shipping_fee'        => $this->shippingFee,
            'discount'            => $this->discount,
            'tax'                 => $this->tax,
            'total'               => $this->total,
            'currency'            => $this->currency,
            'notes'               => $this->notes,
            'created_at'          => $this->createdAt,
        ];
    }
    public static function fromRow(object $row): self
    {
        return new self(
            orderId: (int) $row->OrderID,
            orderNumber: (string) $row->OrderNumber,
            userId: (int) $row->UserID,
            billingAddressId: (int) $row->BillingAddressID,
            shippingAddressId: (int) $row->ShippingAddressID,
            orderStatusId: (int) $row->OrderStatusID,
            paymentMethodId: (int) $row->PaymentMethodID,
            subtotal: (float) $row->Subtotal,
            shippingFee: (float) $row->ShippingFee,
            discount: (float) $row->Discount,
            tax: (float) $row->Tax,
            total: (float) $row->Total,
            currency: (string) $row->Currency,
            notes: $row->Notes,
            createdAt: (string) $row->OrderedAt,
        );
    }
}
