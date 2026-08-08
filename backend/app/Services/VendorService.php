<?php

namespace App\Services;

use App\DTOs\Vendor\VendorProfileDto;
use App\DTOs\Vendor\VendorPublicProfileResponseDto;
use App\Services\Interface\VendorServiceInterface;
use App\Repositories\Interface\VendorRepositoryInterface;

class VendorService implements VendorServiceInterface
{
    public function __construct(
        protected VendorRepositoryInterface $vendorRepository
    ) {
    }

    public function getVendorProfileByUserId(int $userId): ?VendorProfileDto
    {
        $row = $this->vendorRepository->findByUserId($userId);

        return $row ? VendorProfileDto::fromDbRow($row) : null;
    }
       public function getPublicProfile(int $vendorProfileID): ?VendorPublicProfileResponseDto
    {
        $row = $this->vendorRepository->getPublicProfile($vendorProfileID);

        return $row ? VendorPublicProfileResponseDto::fromRow($row) : null;
    }
}