<?php

namespace App\DTOs\Promotion;

use Carbon\Carbon;

class CreatePromotionForCategoryDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $categoryId,
        public readonly string $name,
        public readonly ?string $description,
        public readonly ?string $promoCode,
        public readonly string $discountTypeCode,
        public readonly float $discountValue,
        public readonly ?float $maxDiscountAmount,
        public readonly ?float $minOrderAmount,
        public readonly ?int $usageLimitTotal,
        public readonly ?int $usageLimitPerUser,
        public readonly string $startDate,
        public readonly string $endDate,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['UserPublicID'],
            categoryId: $data['CategoryID'],
            name: $data['Name'],
            description: $data['Description'] ?? null,
            promoCode: $data['PromoCode'] ?? null,
            discountTypeCode: $data['DiscountTypeCode'],
            discountValue: $data['DiscountValue'],
            maxDiscountAmount: $data['MaxDiscountAmount'] ?? null,
            minOrderAmount: $data['MinOrderAmount'] ?? null,
            usageLimitTotal: $data['UsageLimitTotal'] ?? null,
            usageLimitPerUser: $data['UsageLimitPerUser'] ?? null,
            startDate: Carbon::parse($data['StartDate'])->format('Y-m-d H:i:s'),
            endDate: Carbon::parse($data['EndDate'])->format('Y-m-d H:i:s'),
        );
    }
}