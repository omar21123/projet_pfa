<?php

namespace App\Repositories\Interface;

use App\DTOs\Vendor\PaginatedVendorWithdrawHistoryDto;
use App\DTOs\Vendor\RequestVendorWithdrawDto;
use App\DTOs\Vendor\VendorBankAccountDto;
use App\DTOs\Vendor\VendorProfileResponseDto;
use App\DTOs\Vendor\VendorPublicProfileResponseDto;

interface VendorRepositoryInterface
{
    public function findByUserId(int $userId): ?object;
    public function getPublicProfile(int $vendorProfileID): ?VendorPublicProfileResponseDto;
    public function findByProductId(int $productId): ?VendorProfileResponseDto;
    public function getVendorProducts(
        int     $vendorProfileID,
        ?string $userPublicID,
        ?int    $categoryID,
        int     $pageNumber,
        int     $pageSize
    ): array;
    // Interface additions

    public function getBankAccountByVendorProfileId(int $vendorProfileId): ?VendorBankAccountDto;

    public function getVendorWithdrawHistory(int $vendorProfileId, int $page, int $perPage): PaginatedVendorWithdrawHistoryDto;

    public function requestVendorWithdraw(RequestVendorWithdrawDto $dto): int;
}
