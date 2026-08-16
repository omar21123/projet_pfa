<?php
// app/DTOs/Delivery/RemitCashResultDto.php
namespace App\DTOs\Delivery;

class RemitCashResultDto
{
    public function __construct(
        public readonly string $message,
        public readonly float $totalRemitted,
    ) {}

    public function toArray(): array
    {
        return [
            'message'        => $this->message,
            'total_remitted' => $this->totalRemitted,
        ];
    }
}