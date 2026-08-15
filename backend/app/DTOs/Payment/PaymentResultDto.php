<?php
// app/DTOs/Payment/PaymentResultDto.php

namespace App\DTOs\Payment;

class PaymentResultDto
{
    public function __construct(
        public readonly int $paymentId,
        public readonly string $message,
    ) {
    }

    public static function fromOutput(object $row): self
    {
        return new self(
            paymentId: (int) $row->paymentId,
            message: (string) $row->message,
        );
    }

    public function toArray(): array
    {
        return [
            'PaymentID' => $this->paymentId,
            'Message'   => $this->message,
        ];
    }
}