<?php

namespace App\DTOs\Vendor;

use Carbon\Carbon;

final class VendorProfileDto
{
    public function __construct(
        public readonly int $vendorProfileId,
        public readonly int $userId,
        public readonly string $storeName,
        public readonly ?string $description,
        public readonly ?string $logoUrl,
        public readonly ?string $bannerUrl,
        public readonly float $rating,
        public readonly int $reviewCount,
        public readonly bool $identityVerified,
        public readonly bool $businessVerified,
        public readonly bool $bankVerified,
        public readonly int $verificationStatus,
        public readonly bool $isApproved,
        public readonly bool $isSuspended,
        public readonly ?Carbon $suspendedAt,
        public readonly ?Carbon $approvedAt,
        public readonly Carbon $createdAt,
        public readonly Carbon $updatedAt,
        public readonly ?int $verifiedBy,
        public readonly ?string $verificationNotes,
        public readonly ?string $rejectionNotes,
        public readonly ?int $suspendedBy,
        public readonly ?string $suspensionNotes,
    ) {
    }

    /**
     * Maps a raw DB row (stdClass returned by DB::selectOne) from the
     * VendorProfiles table into the DTO.
     */
    public static function fromDbRow(object $row): self
    {
        return new self(
            vendorProfileId: (int) $row->VendorProfileID,
            userId: (int) $row->UserID,
            storeName: $row->StoreName,
            description: $row->Description,
            logoUrl: $row->LogoURL,
            bannerUrl: $row->BannerURL,
            rating: (float) $row->Rating,
            reviewCount: (int) $row->ReviewCount,
            identityVerified: (bool) $row->IdentityVerified,
            businessVerified: (bool) $row->BusinessVerified,
            bankVerified: (bool) $row->BankVerified,
            verificationStatus: (int) $row->VerificationStatus,
            isApproved: (bool) $row->IsApproved,
            isSuspended: (bool) $row->IsSuspended,
            suspendedAt: $row->SuspendedAt !== null ? Carbon::parse($row->SuspendedAt) : null,
            approvedAt: $row->ApprovedAt !== null ? Carbon::parse($row->ApprovedAt) : null,
            createdAt: Carbon::parse($row->CreatedAt),
            updatedAt: Carbon::parse($row->UpdatedAt),
            verifiedBy: $row->VerifiedBy !== null ? (int) $row->VerifiedBy : null,
            verificationNotes: $row->VerificationNotes,
            rejectionNotes: $row->RejectionNotes,
            suspendedBy: $row->SuspendedBy !== null ? (int) $row->SuspendedBy : null,
            suspensionNotes: $row->SuspensionNotes,
        );
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'vendor_profile_id' => $this->vendorProfileId,
            'user_id' => $this->userId,
            'store_name' => $this->storeName,
            'description' => $this->description,
            'logo_url' => $this->logoUrl,
            'banner_url' => $this->bannerUrl,
            'rating' => $this->rating,
            'review_count' => $this->reviewCount,
            'identity_verified' => $this->identityVerified,
            'business_verified' => $this->businessVerified,
            'bank_verified' => $this->bankVerified,
            'verification_status' => $this->verificationStatus,
            'is_approved' => $this->isApproved,
            'is_suspended' => $this->isSuspended,
            'suspended_at' => $this->suspendedAt?->toDateTimeString(),
            'approved_at' => $this->approvedAt?->toDateTimeString(),
            'created_at' => $this->createdAt->toDateTimeString(),
            'updated_at' => $this->updatedAt->toDateTimeString(),
        ];
    }
}