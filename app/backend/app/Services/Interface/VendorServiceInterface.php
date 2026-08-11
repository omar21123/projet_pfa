<?php

namespace App\Services\Interface;

use App\DTOs\Vendor\VendorProfileDto;
use App\DTOs\Vendor\VendorPublicProfileResponseDto;

interface VendorServiceInterface
{
    public function getVendorProfileByUserId(int $userId): ?VendorProfileDto;
        public function getPublicProfile(int $vendorProfileID): ?VendorPublicProfileResponseDto;

}