<?php
// app/DTOs/Delivery/PendingCashSummaryDto.php
namespace App\DTOs\Delivery;

class PendingCashSummaryDto
{
    public function __construct(
        public readonly array $items,
        public readonly float $totalDue,
    ) {}

    public function toArray(): array
    {
        return [
            'items'     => array_map(fn($i) => $i->toArray(), $this->items),
            'total_due' => $this->totalDue,
        ];
    }
}