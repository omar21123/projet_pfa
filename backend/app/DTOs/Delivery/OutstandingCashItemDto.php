<?php
// app/DTOs/Delivery/OutstandingCashItemDto.php
namespace App\DTOs\Delivery;

class OutstandingCashItemDto
{
    public function __construct(
        public readonly int $deliveryProfileId,
        public readonly string $displayName,
        public readonly string $email,
        public readonly ?string $phoneNumber,
        public readonly float $outstandingAmount,
        public readonly int $pendingDeliveriesCount,
        public readonly ?string $oldestCollectedAt,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            deliveryProfileId: (int) $row->DeliveryProfileID,
            displayName: $row->DisplayName,
            email: $row->Email,
            phoneNumber: $row->PhoneNumber,
            outstandingAmount: (float) $row->OutstandingAmount,
            pendingDeliveriesCount: (int) $row->PendingDeliveriesCount,
            oldestCollectedAt: $row->OldestCollectedAt,
        );
    }

    public function toArray(): array
    {
        return [
            'delivery_profile_id'      => $this->deliveryProfileId,
            'display_name'             => $this->displayName,
            'email'                    => $this->email,
            'phone_number'             => $this->phoneNumber,
            'outstanding_amount'       => $this->outstandingAmount,
            'pending_deliveries_count' => $this->pendingDeliveriesCount,
            'oldest_collected_at'      => $this->oldestCollectedAt,
        ];
    }
}