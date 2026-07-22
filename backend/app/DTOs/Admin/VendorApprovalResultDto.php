<?php

namespace App\DTOs\Admin;

class VendorApprovalResultDto
{
    public function __construct(
        public readonly int $vendorProfileId,
        public readonly int $verificationStatus,
        public readonly bool $isApproved,
        public readonly ?string $approvedAt,
        public readonly ?int $verifiedBy,
        public readonly ?string $verificationNotes,
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            vendorProfileId: (int) $row->VendorProfileID,
            verificationStatus: (int) $row->VerificationStatus,
            isApproved: (bool) $row->IsApproved,
            approvedAt: $row->ApprovedAt,
            verifiedBy: $row->VerifiedBy !== null ? (int) $row->VerifiedBy : null,
            verificationNotes: $row->VerificationNotes,
        );
    }
}