<?php

namespace App\DTOs\Product;

class ProductDetailsDto
{
    public function __construct(
        public readonly object $details,
        public readonly array $tags,
        public readonly array $allowedPayments,
        public readonly array $categories,
        public readonly array $configs,
        public readonly array $resources = [],
    ) {}

    public function toArray(): array
    {
        return [
            'details' => [
                'product_id'       => (int) $this->details->ProductId,
                'product_name'     => $this->details->ProductName,
                'full_name'        => $this->details->FullName,
                'brand_name'       => $this->details->BrandName,
                'brand_logo'       => $this->details->BrandLogo,
                'model_name'       => $this->details->ModelName,
                'status'           => $this->details->Status,
                'barcode'          => $this->details->Barcode,
                'stock'            => (int) $this->details->Stock,
                'created_at'       => $this->details->CreatedAt,
                'refuse_attempt'   => $this->details->RefuseAttempt !== null ? (int) $this->details->RefuseAttempt : null,
                'refuse_notes'     => $this->details->RefuseNotes,
                'refused_by'       => $this->details->RefusedBy,
                'refuse_at'        => $this->details->RefuseAt,
                'validator_by'     => $this->details->ValidatorBy,
                'validation_notes' => $this->details->ValidationNotes,
                'validation_date'  => $this->details->ValidationDate,
                'is_active'        => (bool) $this->details->IsActive,
                'deleted_at'       => $this->details->DeletedAt,
                'is_blocked'       => (bool) $this->details->IsBlocked,
                'blocked_date'     => $this->details->BlockedDate,
                'blocked_notes'    => $this->details->BlockedNotes,
            ],
            'tags' => array_map(fn ($row) => $row->Name, $this->tags),
            'allowed_payments' => array_map(fn ($row) => [
                'name'     => $row->PaymentName,
                'code'     => $row->Code,
                'icon_url' => $row->IconURL,
            ], $this->allowedPayments),
            'categories' => array_map(fn ($row) => [
                'name'       => $row->Name,
                'icon_url'   => $row->IconURL,
                'is_primary' => (bool) $row->IsPrimary,
            ], $this->categories),
            'configs' => array_map(fn ($row) => [
                'attribute'   => $row->Attribute,
                'option'      => $row->OptionValue,
                'is_default'  => (bool) $row->IsDefaultForAttribute,
            ], $this->configs),
            // 🎯 Séparation images/vidéos à partir du même resultset "resources",
            // en se basant sur la colonne Type ('image' | 'video')
            'images' => array_values(array_map(fn ($row) => [
                'url'  => $row->Path,
                'role' => (int) $row->Role,
            ], array_filter(
                $this->resources,
                fn ($row) => strtolower($row->Type) === 'image'
            ))),
            'videos' => array_values(array_map(fn ($row) => [
                'url'  => $row->Path,
                'role' => (int) $row->Role,
            ], array_filter(
                $this->resources,
                fn ($row) => strtolower($row->Type) === 'video'
            ))),
        ];
    }
}