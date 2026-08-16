<?php
// app/DTOs/Delivery/PendingCashItemDto.php
namespace App\DTOs\Delivery;

class PendingCashItemDto
{
    public function __construct(
        public readonly int $deliveryId,
        public readonly int $orderId,
        public readonly float $collectedAmount,
        public readonly ?string $collectedAt,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            deliveryId: (int) $row->DeliveryID,
            orderId: (int) $row->OrderID,
            collectedAmount: (float) $row->CollectedAmount,
            collectedAt: $row->CollectedAt,
        );
    }

    public function toArray(): array
    {
        return [
            'delivery_id'      => $this->deliveryId,
            'order_id'         => $this->orderId,
            'collected_amount' => $this->collectedAmount,
            'collected_at'     => $this->collectedAt,
        ];
    }
}