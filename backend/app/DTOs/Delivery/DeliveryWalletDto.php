<?php
// app/DTOs/Delivery/DeliveryWalletDto.php
namespace App\DTOs\Delivery;

class DeliveryWalletDto
{
    public function __construct(
        public readonly int $deliveryWalletId,
        public readonly int $deliveryProfileId,
        public readonly float $currentBalance,
        public readonly float $withdrawableBalance,
        public readonly float $pendingBalance,
        public readonly string $currencyCode,
        public readonly bool $isLocked,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            deliveryWalletId: (int) $row->DeliveryWalletID,
            deliveryProfileId: (int) $row->DeliveryProfileID,
            currentBalance: (float) $row->CurrentBalance,
            withdrawableBalance: (float) $row->WithdrawableBalance,
            pendingBalance: (float) $row->PendingBalance,
            currencyCode: $row->CurrencyCode,
            isLocked: (bool) $row->IsLocked,
        );
    }

    public function toArray(): array
    {
        return [
            'delivery_wallet_id'   => $this->deliveryWalletId,
            'delivery_profile_id'  => $this->deliveryProfileId,
            'current_balance'      => $this->currentBalance,
            'withdrawable_balance' => $this->withdrawableBalance,
            'pending_balance'      => $this->pendingBalance,
            'currency_code'        => $this->currencyCode,
            'is_locked'            => $this->isLocked,
        ];
    }
}