<?php
// app/DTOs/Delivery/GetAllDeliveryProfilesDto.php

namespace App\DTOs\Delivery;

class GetAllDeliveryProfilesDto
{
    public function __construct(
        public readonly ?string $search,
        public readonly ?bool $isAvailable,
        public readonly ?bool $isApproved,
        public readonly ?bool $isSuspended,
        public readonly int $page,
        public readonly int $perPage,
    ) {
    }

    public static function fromRequest(array $validated): self
    {
        return new self(
            search: $validated['search'] ?? null,
            isAvailable: array_key_exists('is_available', $validated) ? (bool) $validated['is_available'] : null,
            isApproved: array_key_exists('is_approved', $validated) ? (bool) $validated['is_approved'] : null,
            isSuspended: array_key_exists('is_suspended', $validated) ? (bool) $validated['is_suspended'] : null,
            page: (int) ($validated['page'] ?? 1),
            perPage: (int) ($validated['per_page'] ?? 20),
        );
    }
}