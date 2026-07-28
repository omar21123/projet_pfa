<?php

namespace App\DTOs\Product\vendor;

class VendorProductItemDto
{
    public function __construct(
        public readonly int $productId,
        public readonly string $name,
        public readonly ?string $barcode,
        public readonly float $basePrice,
        public readonly int $stock,
        public readonly int $status,
        public readonly string $statusLabel,
        public readonly bool $isActive,
        public readonly bool $isBlocked,
        public readonly ?string $brandName,
        public readonly ?string $modelName,
        public readonly ?string $mainImage,
        public readonly string $createdAt,
        public readonly string $updatedAt,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            productId: (int) $row->ProductID,
            name: $row->Name,
            barcode: $row->Barcode,
            basePrice: (float) $row->BasePrice,
            stock: (int) $row->Stock,
            status: (int) $row->Status,
            statusLabel: $row->StatusLabel,
            isActive: (bool) $row->IsActive,
            isBlocked: (bool) $row->IsBlocked,
            brandName: $row->BrandName,
            modelName: $row->ModelName,
            mainImage: $row->MainImage,
            createdAt: $row->CreatedAt,
            updatedAt: $row->UpdatedAt,
        );
    }

    public function toArray(): array
    {
        return [
            'product_id'   => $this->productId,
            'name'         => $this->name,
            'barcode'      => $this->barcode,
            'base_price'   => $this->basePrice,
            'stock'        => $this->stock,
            'status'       => $this->status,
            'status_label' => $this->statusLabel,
            'is_active'    => $this->isActive,
            'is_blocked'   => $this->isBlocked,
            'brand_name'   => $this->brandName,
            'model_name'   => $this->modelName,
            'main_image'   => $this->mainImage,
            'created_at'   => $this->createdAt,
            'updated_at'   => $this->updatedAt,
        ];
    }
}