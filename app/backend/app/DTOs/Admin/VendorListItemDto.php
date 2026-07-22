<?php

namespace App\DTOs\Admin;

readonly class VendorListItemDto
{
    public function __construct(
        public int $vendorProfileId,
        public string $storeName,
        public ?string $logoUrl,
        public string $firstName,
        public string $lastName,
        public string $email,
        public ?string $phoneNumber,
        public ?string $lastLoginAt,
        public bool $isActive,
        public string $verificationStatus,
        public bool $identityVerified,
        public bool $businessVerified,
        public bool $bankVerified,
        public bool $isApproved,
        public bool $isSuspended,
        public ?string $suspendedAt,
        public float $rating,
        public int $reviewCount,
        public string $createdAt,
        public int $totalProducts,
        public int $activeProducts,
        public int $totalOrders,
        public float $totalRevenue,
        public ?float $withdrawableBalance,
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            vendorProfileId: (int) $row->VendorProfileID,
            storeName: $row->StoreName,
            logoUrl: $row->LogoURL,
            firstName: $row->FirstName,
            lastName: $row->LastName,
            email: $row->Email,
            phoneNumber: $row->PhoneNumber,
            lastLoginAt: $row->LastLoginAt,
            isActive: (bool) $row->IsActive,
            verificationStatus: (string) $row->VerificationStatus,
            identityVerified: (bool) $row->IdentityVerified,
            businessVerified: (bool) $row->BusinessVerified,
            bankVerified: (bool) $row->BankVerified,
            isApproved: (bool) $row->IsApproved,
            isSuspended: (bool) $row->IsSuspended,
            suspendedAt: $row->SuspendedAt,
            rating: (float) $row->Rating,
            reviewCount: (int) $row->ReviewCount,
            createdAt: $row->CreatedAt,
            totalProducts: (int) $row->TotalProducts,
            activeProducts: (int) $row->ActiveProducts,
            totalOrders: (int) $row->TotalOrders,
            totalRevenue: (float) $row->TotalRevenue,
            withdrawableBalance: $row->WithdrawableBalance !== null ? (float) $row->WithdrawableBalance : null,
        );
    }
}