<?php

namespace App\Adapters\Payment;

class PaymentResultStripe
{
    public function __construct(
        public readonly string $provider,
        public readonly string $transactionId,
        public readonly string $status,
    ) {
    }
}
