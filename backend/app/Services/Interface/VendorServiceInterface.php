<?php

namespace App\Services\Interface;

use App\DTOs\Vendor\VendorProfileDto;

interface VendorServiceInterface
{
    public function getVendorProfileByUserId(int $userId): ?VendorProfileDto;
}