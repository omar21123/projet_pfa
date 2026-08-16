<?php
// app/DTOs/Vendor/VendorBankAccountDto.php
namespace App\DTOs\Vendor;

class VendorBankAccountDto
{
    public function __construct(
        public readonly int $bankAccountId,
        public readonly int $vendorProfileId,
        public readonly float $currentBalance,
        public readonly float $withdrawableBalance,
        public readonly float $pendingBalance,
        public readonly string $currencyCode,
        public readonly bool $isLocked,
        public readonly float $totalHeld,
        public readonly int $activeHoldsCount,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            bankAccountId: (int) $row->BankAccountID,
            vendorProfileId: (int) $row->VendorProfileID,
            currentBalance: (float) $row->CurrentBalance,
            withdrawableBalance: (float) $row->WithdrawableBalance,
            pendingBalance: (float) $row->PendingBalance,
            currencyCode: $row->CurrencyCode,
            isLocked: (bool) $row->IsLocked,
            totalHeld: (float) ($row->TotalHeld ?? 0),
            activeHoldsCount: (int) ($row->ActiveHoldsCount ?? 0),
        );
    }

    public function toArray(): array
    {
        return [
            'bank_account_id'      => $this->bankAccountId,
            'vendor_profile_id'    => $this->vendorProfileId,
            'current_balance'      => $this->currentBalance,
            'withdrawable_balance' => $this->withdrawableBalance,
            'pending_balance'      => $this->pendingBalance,
            'currency_code'        => $this->currencyCode,
            'is_locked'            => $this->isLocked,
            'total_held'           => $this->totalHeld,
            'active_holds_count'   => $this->activeHoldsCount,
        ];
    }
}