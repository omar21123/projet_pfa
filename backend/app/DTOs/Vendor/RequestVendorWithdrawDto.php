<?php
// app/DTOs/Vendor/RequestVendorWithdrawDto.php
namespace App\DTOs\Vendor;

class RequestVendorWithdrawDto
{
    public function __construct(
        public readonly int $vendorProfileId,
        public readonly float $amount,
        public readonly int $paymentMethodId,
    ) {}
}