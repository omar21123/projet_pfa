<?php
// app/DTOs/Delivery/GetDeliveryHistoryDto.php

namespace App\DTOs\Delivery;

class GetDeliveryHistoryDto
{
    public function __construct(
        public readonly int $deliveryProfileId,
        public readonly ?string $statusCode,
        public readonly ?string $dateFrom,
        public readonly ?string $dateTo,
        public readonly int $page,
        public readonly int $perPage,
    ) {
    }

    public static function fromRequest(array $validated, int $deliveryProfileId): self
    {
        return new self(
            deliveryProfileId: $deliveryProfileId,
            statusCode: $validated['status'] ?? null,
            dateFrom: $validated['date_from'] ?? null,
            dateTo: $validated['date_to'] ?? null,
            page: (int) ($validated['page'] ?? 1),
            perPage: (int) ($validated['per_page'] ?? 20),
        );
    }
}