<?php

namespace App\DTOs\Promotion;

class PromotionDto
{
    public function __construct(
        public readonly int $promotionId,
        public readonly int $vendorId,
        public readonly string $name,
        public readonly ?string $description,
        public readonly ?string $promoCode,
        public readonly string $discountTypeCode,
        public readonly string $discountTypeLabel,
        public readonly float $discountValue,
        public readonly ?float $maxDiscountAmount,
        public readonly ?float $minOrderAmount,
        public readonly string $scopeTypeCode,
        public readonly string $scopeTypeLabel,
        public readonly ?int $targetProductId,
        public readonly ?int $targetCategoryId,
        public readonly ?int $usageLimitTotal,
        public readonly int $usageLimitPerUser,
        public readonly int $usageCount,
        public readonly string $startDate,
        public readonly string $endDate,
        public readonly string $statusCode,
        public readonly string $statusLabel,
        public readonly bool $isActive,
        public readonly string $createdAt,
        public readonly string $updatedAt,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            promotionId: (int) $row->PromotionID,
            vendorId: (int) $row->VendorID,
            name: $row->Name,
            description: $row->Description,
            promoCode: $row->PromoCode,
            discountTypeCode: $row->DiscountTypeCode,
            discountTypeLabel: $row->DiscountTypeLabel,
            discountValue: (float) $row->DiscountValue,
            maxDiscountAmount: $row->MaxDiscountAmount !== null ? (float) $row->MaxDiscountAmount : null,
            minOrderAmount: $row->MinOrderAmount !== null ? (float) $row->MinOrderAmount : null,
            scopeTypeCode: $row->ScopeTypeCode,
            scopeTypeLabel: $row->ScopeTypeLabel,
            targetProductId: $row->TargetProductID !== null ? (int) $row->TargetProductID : null,
            targetCategoryId: $row->TargetCategoryID !== null ? (int) $row->TargetCategoryID : null,
            usageLimitTotal: $row->UsageLimitTotal !== null ? (int) $row->UsageLimitTotal : null,
            usageLimitPerUser: (int) $row->UsageLimitPerUser,
            usageCount: (int) $row->UsageCount,
            startDate: (string) $row->StartDate,
            endDate: (string) $row->EndDate,
            statusCode: $row->StatusCode,
            statusLabel: $row->StatusLabel,
            isActive: (bool) $row->IsActive,
            createdAt: (string) $row->CreatedAt,
            updatedAt: (string) $row->UpdatedAt,
        );
    }

    public function toArray(): array
    {
        return [
            'promotion_id'         => $this->promotionId,
            'vendor_id'            => $this->vendorId,
            'name'                 => $this->name,
            'description'          => $this->description,
            'promo_code'           => $this->promoCode,
            'discount_type'        => ['code' => $this->discountTypeCode, 'label' => $this->discountTypeLabel],
            'discount_value'       => $this->discountValue,
            'max_discount_amount'  => $this->maxDiscountAmount,
            'min_order_amount'     => $this->minOrderAmount,
            'scope_type'           => ['code' => $this->scopeTypeCode, 'label' => $this->scopeTypeLabel],
            'target_product_id'    => $this->targetProductId,
            'target_category_id'   => $this->targetCategoryId,
            'usage_limit_total'    => $this->usageLimitTotal,
            'usage_limit_per_user' => $this->usageLimitPerUser,
            'usage_count'          => $this->usageCount,
            'start_date'           => $this->startDate,
            'end_date'             => $this->endDate,
            'status'               => ['code' => $this->statusCode, 'label' => $this->statusLabel],
            'is_active'            => $this->isActive,
            'created_at'           => $this->createdAt,
            'updated_at'           => $this->updatedAt,
        ];
    }
}