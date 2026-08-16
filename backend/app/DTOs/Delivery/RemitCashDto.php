<?php
// app/DTOs/Delivery/RemitCashDto.php
namespace App\DTOs\Delivery;

class RemitCashDto
{
    public function __construct(
        public readonly int $deliveryProfileId,
        public readonly int $adminUserId,
        public readonly ?float $expectedAmount,
    ) {}
}