<?php

namespace App\DTOs\Product;

class PromotionDetailsDto
{
    public function __construct(
        public readonly string $code,
        public readonly float $discountValue,
    ) {}

    public static function fromRow(object $row): ?self
    {
        // Pas de promo active pour ce produit -> pas de détails à construire.
        if (empty($row->PromotionCode) && $row->PromotionDiscountValue === null) {
            return null;
        }

        return new self(
            code: $row->PromotionCode,
            discountValue: (float) $row->PromotionDiscountValue,
        );
    }

    public function toArray(): array
    {
        return [
            'Code'          => $this->code,
            'DiscountValue' => $this->discountValue,
        ];
    }
}