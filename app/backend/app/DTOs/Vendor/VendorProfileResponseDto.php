<?php
// App\DTOs\Vendor\VendorProfileResponseDto
namespace App\DTOs\Vendor;

class VendorProfileResponseDto
{
    public function __construct(
        public readonly string  $vendorProfileID,
        public readonly string  $storeName,
        public readonly ?string $memberSince,
        public readonly bool    $identityVerified,
        public readonly bool    $businessVerified,
        public readonly bool    $isApproved,
        public readonly ?string $LogoURL ,
        public readonly ?string  $BannerURL 
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            vendorProfileID:  $row->VendorProfileID,
            storeName:        $row->StoreName,
            LogoURL : $row->LogoURL,
            BannerURL : $row->BannerURL,
            memberSince:      $row->MemberSince   ?? null,
            identityVerified: (bool) $row->IdentityVerified,
            businessVerified: (bool) $row->BusinessVerified,
            isApproved:       (bool) $row->IsApproved,
        );
    }

    public function toArray(): array
    {
        return [
            'VendorProfileID'   => $this->vendorProfileID,
            'StoreName'         => $this->storeName,
             'BannerURL' =>$this->BannerURL,
             'LogoURL' => $this->LogoURL,
            'MemberSince'       => $this->memberSince,
            'IdentityVerified'  => $this->identityVerified,
            'BusinessVerified'  => $this->businessVerified,
            'IsApproved'        => $this->isApproved,
        ];
    }
}