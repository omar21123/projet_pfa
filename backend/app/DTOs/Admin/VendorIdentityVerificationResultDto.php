<?php

namespace App\DTOs\Admin;

class VendorIdentityVerificationResultDto
{
    public function __construct(
        public readonly int $vendorProfileId,
        public readonly bool $identityVerified,
        public readonly bool $businessVerified,
        public readonly bool $bankVerified,
        public readonly int $verificationStatus,
        public readonly ?int $verifiedBy,
        public readonly ?string $verificationNotes,
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            vendorProfileId: (int) $row->VendorProfileID,
            identityVerified: (bool) $row->IdentityVerified,
            businessVerified: (bool) $row->BusinessVerified,
            bankVerified: (bool) $row->BankVerified,
            verificationStatus: (int) $row->VerificationStatus,
            verifiedBy: $row->VerifiedBy !== null ? (int) $row->VerifiedBy : null,
            verificationNotes: $row->VerificationNotes,
        );
    }
}