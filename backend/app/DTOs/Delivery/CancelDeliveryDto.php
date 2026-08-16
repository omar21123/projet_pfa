<?php
// app/DTOs/Delivery/CancelDeliveryDto.php
namespace App\DTOs\Delivery;

class CancelDeliveryDto
{
    public function __construct(
        public readonly int $deliveryId,
        public readonly int $adminUserId,
        public readonly ?string $reason,
    ) {}

    public static function fromRequest(array $validated, int $deliveryId, int $adminUserId): self
    {
        return new self(
            deliveryId: $deliveryId,
            adminUserId: $adminUserId,
            reason: $validated['Reason'] ?? null,
        );
    }
}