<?php

namespace App\Repositories\Interface;

use App\DTOs\Admin\ApproveVendorDto;
use App\DTOs\Admin\RejectVendorDto;
use App\DTOs\Admin\ResetVendorToPendingDto;
use App\DTOs\Admin\VendorListFilterDto;
use App\DTOs\Admin\VerifyIdentityDto;

interface AdminVendorRepositoryInterface
{
    /**
     * @return array{total: int, items: array<int, object>}
     */
    public function getVendorsList(VendorListFilterDto $filter): array;
    public function verifyIdentity(VerifyIdentityDto $dto): object;
    public function approveVendor(ApproveVendorDto $dto): object;
    public function rejectVendor(RejectVendorDto $dto): object;
    public function resetVendorToPending(ResetVendorToPendingDto $dto): object;
}