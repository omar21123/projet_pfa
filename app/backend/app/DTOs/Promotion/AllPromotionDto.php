<?php

namespace App\DTOs\Promotion;

class AllPromotionDto
{
    public function __construct(
        public readonly int $promotionId,
        public readonly ?int $vendorId,
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
        public readonly ?string $productName,
        public readonly ?int $targetCategoryId,
        public readonly ?string $categoryName,
        public readonly ?int $usageLimitTotal,
        public readonly ?int $usageLimitPerUser,
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
            vendorId: $row->VendorID !== null ? (int) $row->VendorID : null,
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
            productName: $row->ProductName ?? null,
            targetCategoryId: $row->TargetCategoryID !== null ? (int) $row->TargetCategoryID : null,
            categoryName: $row->CategoryName ?? null,
            usageLimitTotal: $row->UsageLimitTotal !== null ? (int) $row->UsageLimitTotal : null,
            usageLimitPerUser: $row->UsageLimitPerUser !== null ? (int) $row->UsageLimitPerUser : null,
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
            'PromotionID'       => $this->promotionId,
            'VendorID'          => $this->vendorId,
            'Name'              => $this->name,
            'Description'       => $this->description,
            'PromoCode'         => $this->promoCode,
            'DiscountType'      => ['code' => $this->discountTypeCode, 'label' => $this->discountTypeLabel],
            'DiscountValue'     => $this->discountValue,
            'MaxDiscountAmount' => $this->maxDiscountAmount,
            'MinOrderAmount'    => $this->minOrderAmount,
            'ScopeType'         => ['code' => $this->scopeTypeCode, 'label' => $this->scopeTypeLabel],
            'TargetProductID'   => $this->targetProductId,
            'ProductName'       => $this->productName,
            'TargetCategoryID'  => $this->targetCategoryId,
            'CategoryName'      => $this->categoryName,
            'UsageLimitTotal'   => $this->usageLimitTotal,
            'UsageLimitPerUser' => $this->usageLimitPerUser,
            'UsageCount'        => $this->usageCount,
            'StartDate'         => $this->startDate,
            'EndDate'           => $this->endDate,
            'Status'            => ['code' => $this->statusCode, 'label' => $this->statusLabel],
            'IsActive'          => $this->isActive,
            'CreatedAt'         => $this->createdAt,
            'UpdatedAt'         => $this->updatedAt,
        ];
    }
}