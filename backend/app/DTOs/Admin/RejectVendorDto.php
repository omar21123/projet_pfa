<?php

namespace App\DTOs\Admin;

class RejectVendorDto
{
    public function __construct(
        public readonly int $vendorProfileId,
        public readonly int $verifiedBy,
        public readonly ?string $rejectionNotes,
    ) {
    }

    public static function fromRequest(int $vendorProfileId, int $verifiedBy, ?string $rejectionNotes): self
    {
        return new self(
            vendorProfileId: $vendorProfileId,
            verifiedBy: $verifiedBy,
            rejectionNotes: $rejectionNotes,
        );
    }
}