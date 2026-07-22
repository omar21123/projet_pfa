<?php

namespace App\DTOs\Admin;

class VerifyIdentityDto
{
    public function __construct(
        public readonly int $vendorProfileId,
        public readonly int $verifiedBy,
        public readonly ?string $verificationNotes,
    ) {
    }

    public static function fromRequest(int $vendorProfileId, int $verifiedBy, ?string $verificationNotes): self
    {
        return new self(
            vendorProfileId: $vendorProfileId,
            verifiedBy: $verifiedBy,
            verificationNotes: $verificationNotes,
        );
    }
}