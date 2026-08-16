<?php
// app/DTOs/Vendor/VendorWithdrawItemDto.php
namespace App\DTOs\Vendor;

class VendorWithdrawItemDto
{
    public function __construct(
        public readonly int $withdrawId,
        public readonly float $amount,
        public readonly int $paymentMethodId,
        public readonly ?string $externalReference,
        public readonly int $status,
        public readonly ?string $notes,
        public readonly ?string $requestedAt,
        public readonly ?string $processedAt,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            withdrawId: (int) $row->WithdrawID,
            amount: (float) $row->Amount,
            paymentMethodId: (int) $row->PaymentMethodID,
            externalReference: $row->ExternalReference,
            status: (int) $row->Status,
            notes: $row->Notes,
            requestedAt: $row->RequestedAt,
            processedAt: $row->ProcessedAt,
        );
    }

    public function toArray(): array
    {
        return [
            'withdraw_id'        => $this->withdrawId,
            'amount'             => $this->amount,
            'payment_method_id'  => $this->paymentMethodId,
            'external_reference' => $this->externalReference,
            'status'             => $this->status,
            'notes'              => $this->notes,
            'requested_at'       => $this->requestedAt,
            'processed_at'       => $this->processedAt,
        ];
    }
}