<?php

namespace App\Repositories\Interface;

use App\DTOs\Vendor\VendorProfileResponseDto;
use App\DTOs\Vendor\VendorPublicProfileResponseDto;

interface VendorRepositoryInterface
{
    public function findByUserId(int $userId): ?object;
    public function getPublicProfile(string $userPublicID): ?VendorPublicProfileResponseDto;
    public function findByProductId(int $productId): ?VendorProfileResponseDto;

}