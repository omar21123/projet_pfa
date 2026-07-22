<?php

namespace App\DTOs\Admin;

class ResetVendorToPendingDto
{
    public function __construct(
        public readonly int $vendorProfileId,
        public readonly int $verifiedBy,
        public readonly ?string $notes,
    ) {
    }

    public static function fromRequest(int $vendorProfileId, int $verifiedBy, ?string $notes): self
    {
        return new self(
            vendorProfileId: $vendorProfileId,
            verifiedBy: $verifiedBy,
            notes: $notes,
        );
    }
}