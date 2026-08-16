<?php
// app/DTOs/Delivery/RequestWithdrawDto.php
namespace App\DTOs\Delivery;

class RequestWithdrawDto
{
    public function __construct(
        public readonly int $deliveryProfileId,
        public readonly float $amount,
        public readonly int $paymentMethodId,
    ) {}
}