<?php

namespace App\Services\Interface;

use App\DTOs\Vendor\PaginatedVendorWithdrawHistoryDto;
use App\DTOs\Vendor\RequestVendorWithdrawDto;
use App\DTOs\Vendor\VendorBankAccountDto;
use App\DTOs\Vendor\VendorProfileDto;
use App\DTOs\Vendor\VendorPublicProfileResponseDto;

interface VendorServiceInterface
{
    public function getVendorProfileByUserId(int $userId): ?VendorProfileDto;
    public function getPublicProfile(int $vendorProfileID): ?VendorPublicProfileResponseDto;
    public function getBankAccountByVendorProfileId(int $vendorProfileId): ?VendorBankAccountDto;

    public function getVendorWithdrawHistory(int $vendorProfileId, int $page, int $perPage): PaginatedVendorWithdrawHistoryDto;

    public function requestVendorWithdraw(RequestVendorWithdrawDto $dto): int;
}
