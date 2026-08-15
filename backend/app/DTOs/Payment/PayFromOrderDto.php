<?php
// app/DTOs/Payment/PayFromOrderDto.php

namespace App\DTOs\Payment;

class PayFromOrderDto
{
    public function __construct(
        public readonly int $orderId,
        public readonly int $paymentMethodId,
        public readonly ?string $transactionId = null,
        public readonly ?string $providerReference = null,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            orderId: $data['OrderID'],
            paymentMethodId: $data['PaymentMethodID'],
            transactionId: $data['TransactionID'] ?? null,
            providerReference: $data['ProviderReference'] ?? null,
        );
    }
}