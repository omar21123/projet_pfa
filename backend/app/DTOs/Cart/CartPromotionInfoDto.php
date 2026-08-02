<?php
// App\DTOs\Cart\CartPromotionInfoDto
namespace App\DTOs\Cart;

class CartPromotionInfoDto
{
    public function __construct(
        public readonly int $promotionId,
        public readonly string $name,
        public readonly ?string $description,
        public readonly string $startDate,
        public readonly string $endDate,
        public readonly float $discountValue,
        public readonly string $code,
        public readonly string $label,
    ) {}
    public function toArray(): array
{
    return [
        'PromotionID'   => $this->promotionId,
        'Name'          => $this->name,
        'Description'   => $this->description,
        'StartDate'     => $this->startDate,
        'EndDate'       => $this->endDate,
        'DiscountValue' => $this->discountValue,
        'Code'          => $this->code,
        'Label'         => $this->label,
    ];
}
    public static function fromRow(object $row): self
    {
        return new self(
            promotionId: (int) $row->PromotionID,
            name: $row->Name,
            description: $row->Description,
            startDate: $row->StartDate,
            endDate: $row->EndDate,
            discountValue: (float) $row->DiscountValue,
            code: $row->Code,
            label: $row->Label,
        );
    }
}