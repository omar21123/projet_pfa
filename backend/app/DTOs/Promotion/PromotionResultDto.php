<?php

namespace App\DTOs\Promotion;

class PromotionResultDto
{
    public function __construct(
        public readonly int $promotionId,
        public readonly string $message,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            promotionId: (int) $data['PromotionID'],
            message: $data['Message'],
        );
    }

    public function toArray(): array
    {
        return [
            'PromotionID' => $this->promotionId,
        ];
    }
}