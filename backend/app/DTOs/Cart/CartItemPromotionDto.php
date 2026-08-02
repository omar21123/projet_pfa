<?php
// App\DTOs\Cart\CartItemPromotionDto
namespace App\DTOs\Cart;

class CartItemPromotionDto
{
    public function __construct(
        public readonly int $promotionId,
        public readonly string $promotionName,
        public readonly ?string $promotionDescription,
        public readonly string $promotionStartDate,
        public readonly string $promotionEndDate,
        public readonly float $discountPercentage,
    ) {}

    public function toArray(): array
    {
        return [
            'PromotionID'          => $this->promotionId,
            'PromotionName'        => $this->promotionName,
            'PromotionDescription' => $this->promotionDescription,
            'PromotionStartDate'   => $this->promotionStartDate,
            'PromotionEndDate'     => $this->promotionEndDate,
            'DiscountPercentage'   => $this->discountPercentage,
        ];
    }
}