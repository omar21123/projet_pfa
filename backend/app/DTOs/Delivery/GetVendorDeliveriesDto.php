<?php
// app/DTOs/Delivery/GetVendorDeliveriesDto.php

namespace App\DTOs\Delivery;

class GetVendorDeliveriesDto
{
    public function __construct(
        public readonly int $vendorProfileId,
        public readonly ?string $statusCode,
        public readonly ?bool $isTaken,
        public readonly int $page,
        public readonly int $perPage,
    ) {
    }

    public static function fromRequest(array $validated, int $vendorProfileId): self
    {
        return new self(
            vendorProfileId: $vendorProfileId,
            statusCode: $validated['status'] ?? null,
            isTaken: array_key_exists('is_taken', $validated) ? (bool) $validated['is_taken'] : null,
            page: (int) ($validated['page'] ?? 1),
            perPage: (int) ($validated['per_page'] ?? 20),
        );
    }
}