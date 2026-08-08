<?php
// App\DTOs\Vendor\VendorPublicProfileResponseDto
namespace App\DTOs\Vendor;

class VendorPublicProfileResponseDto
{
    public function __construct(
        public readonly string  $StoreName,
        public readonly ?string $logoURL,
        public readonly ?string $bannerURL,
        public readonly string  $Note,
        public readonly float   $Rating,
        public readonly int     $ReviewCount,
        public readonly bool    $IdentityVerified,
        public readonly bool    $BusinessVerified,
        public readonly bool    $BankVerified,
        public readonly ?string $description,
        public readonly ?string $approvedAt,
        public readonly float   $ProfileProgress,
        public readonly string  $Address,
        public readonly ?string $hasProductsInCategories,
        public readonly int     $TotalProducts,
        public readonly int     $TotalVentes,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            StoreName:               $row->StoreName,
            logoURL:                 $row->LogoURL                  ?? null,
            bannerURL:               $row->BannerURL                ?? null,
            Note:                    $row->Note,
            Rating:                  (float) $row->Rating,
            ReviewCount:             (int)   $row->ReviewCount,
            IdentityVerified:        (bool)  $row->IdentityVerified,
            BusinessVerified:        (bool)  $row->BusinessVerified,
            BankVerified:            (bool)  $row->BankVerified,
            description:             $row->Description              ?? null,
            approvedAt:              $row->ApprovedAt               ?? null,
            ProfileProgress:         (float) $row->ProfileProgress,
            Address:                 $row->Address,
            hasProductsInCategories: $row->HasProductsInCategories  ?? null,
            TotalProducts:           (int)   $row->TotalProducts,
            TotalVentes:             (int)   $row->TotalVentes,
        );
    }

    public function toArray(): array
    {
        return [
            
            'StoreName'               => $this->StoreName,
            'LogoURL'                 => $this->logoURL,
            'BannerURL'               => $this->bannerURL,
            'Note'                    => $this->Note,
            'Rating'                  => $this->Rating,
            'ReviewCount'             => $this->ReviewCount,
            'IdentityVerified'        => $this->IdentityVerified,
            'BusinessVerified'        => $this->BusinessVerified,
            'BankVerified'            => $this->BankVerified,
            'Description'             => $this->description,
            'ApprovedAt'              => $this->approvedAt,
            'ProfileProgress'         => $this->ProfileProgress,
            'Address'                 => $this->Address,
            'HasProductsInCategories' => $this->hasProductsInCategories,
            'TotalProducts'           => $this->TotalProducts,
            'TotalVentes'             => $this->TotalVentes,
        ];
    }
}