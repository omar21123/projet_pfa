<?php
// App\DTOs\Vendor\VendorPublicProfileResponseDto
namespace App\DTOs\Vendor;

class VendorPublicProfileResponseDto
{
    public function __construct(
        public readonly string  $storeName,
        public readonly ?string $logoURL,
        public readonly ?string $bannerURL,
        public readonly string  $note,
        public readonly float   $rating,
        public readonly int     $reviewCount,
        public readonly bool    $identityVerified,
        public readonly bool    $businessVerified,
        public readonly bool    $bankVerified,
        public readonly ?string $description,
        public readonly ?string $approvedAt,
        public readonly float   $profileProgress,
        public readonly string  $address,
        public readonly ?string $hasProductsInCategories,
        public readonly int     $totalProducts,
        public readonly int     $totalVentes,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            storeName:               $row->StoreName,
            logoURL:                 $row->LogoURL                  ?? null,
            bannerURL:               $row->BannerURL                ?? null,
            note:                    $row->Note,
            rating:                  (float) $row->Rating,
            reviewCount:             (int)   $row->ReviewCount,
            identityVerified:        (bool)  $row->IdentityVerified,
            businessVerified:        (bool)  $row->BusinessVerified,
            bankVerified:            (bool)  $row->BankVerified,
            description:             $row->Description              ?? null,
            approvedAt:              $row->ApprovedAt               ?? null,
            profileProgress:         (float) $row->ProfileProgress,
            address:                 $row->Address,
            hasProductsInCategories: $row->HasProductsInCategories  ?? null,
            totalProducts:           (int)   $row->TotalProducts,
            totalVentes:             (int)   $row->TotalVentes,
        );
    }

    public function toArray(): array
    {
        return [
            'StoreName'               => $this->storeName,
            'LogoURL'                 => $this->logoURL,
            'BannerURL'               => $this->bannerURL,
            'Note'                    => $this->note,
            'Rating'                  => $this->rating,
            'ReviewCount'             => $this->reviewCount,
            'IdentityVerified'        => $this->identityVerified,
            'BusinessVerified'        => $this->businessVerified,
            'BankVerified'            => $this->bankVerified,
            'Description'             => $this->description,
            'ApprovedAt'              => $this->approvedAt,
            'ProfileProgress'         => $this->profileProgress,
            'Address'                 => $this->address,
            'HasProductsInCategories' => $this->hasProductsInCategories,
            'TotalProducts'           => $this->totalProducts,
            'TotalVentes'             => $this->totalVentes,
        ];
    }
}