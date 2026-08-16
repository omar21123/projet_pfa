<?php
// app/DTOs/Delivery/WithdrawHistoryItemDto.php
namespace App\DTOs\Delivery;

class WithdrawHistoryItemDto
{
    public function __construct(
        public readonly int $deliveryWithdrawId,
        public readonly float $amount,
        public readonly int $paymentMethodId,
        public readonly ?string $externalReference,
        public readonly int $status,
        public readonly ?string $requestedAt,
        public readonly ?string $processedAt,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            deliveryWithdrawId: (int) $row->DeliveryWithdrawID,
            amount: (float) $row->Amount,
            paymentMethodId: (int) $row->PaymentMethodID,
            externalReference: $row->ExternalReference,
            status: (int) $row->Status,
            requestedAt: $row->RequestedAt,
            processedAt: $row->ProcessedAt,
        );
    }

    public function toArray(): array
    {
        return [
            'delivery_withdraw_id' => $this->deliveryWithdrawId,
            'amount'               => $this->amount,
            'payment_method_id'    => $this->paymentMethodId,
            'external_reference'   => $this->externalReference,
            'status'               => $this->status,
            'requested_at'         => $this->requestedAt,
            'processed_at'         => $this->processedAt,
        ];
    }
}