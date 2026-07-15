<?php

namespace App\DTOs\Admin;

class VendorRejectionResultDto
{
    public function __construct(
        public readonly int $vendorProfileId,
        public readonly int $verificationStatus,
        public readonly bool $isApproved,
        public readonly ?int $verifiedBy,
        public readonly ?string $rejectionNotes,
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            vendorProfileId: (int) $row->VendorProfileID,
            verificationStatus: (int) $row->VerificationStatus,
            isApproved: (bool) $row->IsApproved,
            verifiedBy: $row->VerifiedBy !== null ? (int) $row->VerifiedBy : null,
            rejectionNotes: $row->RejectionNotes,
        );
    }
}