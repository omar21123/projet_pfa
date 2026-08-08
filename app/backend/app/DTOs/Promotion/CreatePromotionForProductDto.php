<?php

namespace App\DTOs\Promotion;

class CreatePromotionForProductDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $productId,
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
            productId: (int) $data['ProductID'],
            name: $data['Name'],
            description: $data['Description'] ?? null,
            promoCode: $data['PromoCode'] ?? null,
            discountTypeCode: $data['DiscountTypeCode'],
            discountValue: (float) $data['DiscountValue'],
            maxDiscountAmount: isset($data['MaxDiscountAmount']) ? (float) $data['MaxDiscountAmount'] : null,
            minOrderAmount: isset($data['MinOrderAmount']) ? (float) $data['MinOrderAmount'] : null,
            usageLimitTotal: isset($data['UsageLimitTotal']) ? (int) $data['UsageLimitTotal'] : null,
            usageLimitPerUser: isset($data['UsageLimitPerUser']) ? (int) $data['UsageLimitPerUser'] : null,
            startDate: $data['StartDate'],
            endDate: $data['EndDate'],
        );
    }
}