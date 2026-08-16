<?php
// app/DTOs/Order/CustomerOrderItemDto.php

namespace App\DTOs\Order;

class CustomerOrderItemDto
{
    public function __construct(
        public readonly int $orderItemId,
        public readonly int $productId,
        public readonly ?string $productName,
        public readonly ?string $barcode,
        public readonly ?string $productImage,
        public readonly ?int $productVariantId,

        public readonly int $vendorProfileId,
        public readonly ?string $storeName,
        public readonly ?string $vendorEmail,
        public readonly ?string $vendorPhone,
        public readonly ?string $vendorName,

        public readonly float $quantity,
        public readonly float $unitPrice,
        public readonly float $discount,
        public readonly float $tax,
        public readonly float $total,

        public readonly ?int $deliveryId,
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            orderItemId: (int) $row->OrderItemID,
            productId: (int) $row->ProductID,
            productName: $row->ProductName,
            barcode: $row->Barcode,
            productImage: $row->ProductImage,
            productVariantId: $row->ProductVariantID !== null ? (int) $row->ProductVariantID : null,

            vendorProfileId: (int) $row->VendorProfileID,
            storeName: $row->StoreName,
            vendorEmail: $row->VendorEmail,
            vendorPhone: $row->VendorPhone,
            vendorName: $row->VendorName,

            quantity: (float) $row->Quantity,
            unitPrice: (float) $row->UnitPrice,
            discount: (float) $row->Discount,
            tax: (float) $row->Tax,
            total: (float) $row->Total,

            deliveryId: $row->DeliveryID !== null ? (int) $row->DeliveryID : null,
        );
    }

    public function toArray(): array
    {
        return [
            'order_item_id' => $this->orderItemId,
            'product' => [
                'product_id'         => $this->productId,
                'name'               => $this->productName,
                'barcode'            => $this->barcode,
                'image'              => $this->productImage,
                'product_variant_id' => $this->productVariantId,
            ],
            'vendor' => [
                'vendor_profile_id' => $this->vendorProfileId,
                'store_name'        => $this->storeName,
                'email'             => $this->vendorEmail,
                'phone'             => $this->vendorPhone,
                'name'              => $this->vendorName,
            ],
            'quantity'    => $this->quantity,
            'unit_price'  => $this->unitPrice,
            'discount'    => $this->discount,
            'tax'         => $this->tax,
            'total'       => $this->total,
            'delivery_id' => $this->deliveryId,
        ];
    }
}