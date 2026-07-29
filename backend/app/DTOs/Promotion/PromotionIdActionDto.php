<?php

namespace App\DTOs\Promotion;

class PromotionIdActionDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $promotionId,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['UserPublicID'],
            promotionId: (int) $data['PromotionID'],
        );
    }
}