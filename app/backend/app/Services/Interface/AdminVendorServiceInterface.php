<?php

namespace App\Services\Interface;

use App\DTOs\Admin\ApproveVendorDto;
use App\DTOs\Admin\RejectVendorDto;
use App\DTOs\Admin\ResetVendorToPendingDto;
use App\DTOs\Admin\VendorApprovalResultDto;
use App\DTOs\Admin\VendorIdentityVerificationResultDto;
use App\DTOs\Admin\VendorListFilterDto;
use App\DTOs\Admin\VendorRejectionResultDto;
use App\DTOs\Admin\VendorResetResultDto;
use App\DTOs\Admin\VerifyIdentityDto;

interface AdminVendorServiceInterface
{
    public function getAll(VendorListFilterDto $filter): array;
    public function verifyIdentity(VerifyIdentityDto $dto): VendorIdentityVerificationResultDto;
    public function approveVendor(ApproveVendorDto $dto): VendorApprovalResultDto;
    public function rejectVendor(RejectVendorDto $dto): VendorRejectionResultDto;
    public function resetVendorToPending(ResetVendorToPendingDto $dto): VendorResetResultDto;
}