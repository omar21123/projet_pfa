<?php

namespace App\DTOs\Product;

class ProductInfoAllowedPaymentDto
{
    public function __construct(
        public readonly int $paymentMethodId,
        public readonly string $paymentMethodName,
        public readonly string $code,
        public readonly ?string $iconUrl,
        public readonly float $withdrawTax,
        public readonly bool $isOnline,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            paymentMethodId: (int) $row->PaymentMethodID,
            paymentMethodName: $row->Name,
            code: $row->Code,
            iconUrl: $row->IconURL,
            withdrawTax: (float) $row->WithdrawTax,
            isOnline: (bool) $row->IsOnline,
        );
    }

    public function toArray(): array
    {
        return [
            'PaymentMethodName' => $this->paymentMethodName,
            'PaymentMethodID'   => $this->paymentMethodId,
            'code'              => $this->code,
            'IconURL'           => $this->iconUrl,
            'WithdrawTax'       => $this->withdrawTax,
            'IsOnline'          => $this->isOnline,
        ];
    }
}