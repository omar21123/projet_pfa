<?php

namespace App\DTOs\Product;

class ProductInfoPromotionDto
{
    public function __construct(
        public readonly int $promotionId,
        public readonly string $name,
        public readonly ?string $description,
        public readonly string $discountCode,
        public readonly string $discountLabel,
        public readonly float $discountValue,
        public readonly ?float $maxDiscountAmount,
        public readonly ?float $minOrderAmount,
        public readonly ?int $usageLimitTotal,
        public readonly int $usageCount,
        public readonly ?int $usageLimitPerUser,
        public readonly string $startDate,
        public readonly ?string $endDate,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            promotionId: (int) $row->PromotionID,
            name: $row->Name,
            description: $row->Description,
            discountCode: $row->DiscountCode,
            discountLabel: $row->DiscountLabel,
            discountValue: (float) $row->DiscountValue,
            maxDiscountAmount: $row->MaxDiscountAmount !== null ? (float) $row->MaxDiscountAmount : null,
            minOrderAmount: $row->MinOrderAmount !== null ? (float) $row->MinOrderAmount : null,
            usageLimitTotal: $row->UsageLimitTotal !== null ? (int) $row->UsageLimitTotal : null,
            usageCount: (int) $row->UsageCount,
            usageLimitPerUser: $row->UsageLimitPerUser !== null ? (int) $row->UsageLimitPerUser : null,
            startDate: $row->StartDate,
            endDate: $row->EndDate,
        );
    }

    public function toArray(): array
    {
        return [
            'PromotionID'       => $this->promotionId,
            'Name'              => $this->name,
            'Description'       => $this->description,
            'DiscountCode'      => $this->discountCode,
            'DiscountLabel'     => $this->discountLabel,
            'DiscountValue'     => $this->discountValue,
            'MaxDiscountAmount' => $this->maxDiscountAmount,
            'MinOrderAmount'    => $this->minOrderAmount,
            'UsageLimitTotal'   => $this->usageLimitTotal,
            'UsageCount'        => $this->usageCount,
            'UsageLimitPerUser' => $this->usageLimitPerUser,
            'StartDate'         => $this->startDate,
            'EndDate'           => $this->endDate,
        ];
    }
}