<?php

namespace App\Services;

use App\DTOs\Admin\VendorIdentityVerificationResultDto;
use App\DTOs\Admin\VendorListFilterDto;
use App\DTOs\Admin\VendorListItemDto;
use App\DTOs\Admin\VerifyIdentityDto;
use App\Repositories\Interface\AdminVendorRepositoryInterface;
use App\Services\Interface\AdminVendorServiceInterface;
use App\DTOs\Admin\ApproveVendorDto;
use App\DTOs\Admin\VendorApprovalResultDto;
use App\DTOs\Admin\RejectVendorDto;
use App\DTOs\Admin\VendorRejectionResultDto;
use App\DTOs\Admin\ResetVendorToPendingDto;
use App\DTOs\Admin\VendorResetResultDto;

class AdminVendorService implements AdminVendorServiceInterface
{
    public function __construct(private AdminVendorRepositoryInterface $adminVendorRepository) {}
    public function approveVendor(ApproveVendorDto $dto): VendorApprovalResultDto
    {
        $row = $this->adminVendorRepository->approveVendor($dto);

        return VendorApprovalResultDto::fromRow($row);
    }

    public function resetVendorToPending(ResetVendorToPendingDto $dto): VendorResetResultDto
    {
        $row = $this->adminVendorRepository->resetVendorToPending($dto);

        return VendorResetResultDto::fromRow($row);
    }
    public function rejectVendor(RejectVendorDto $dto): VendorRejectionResultDto
    {
        $row = $this->adminVendorRepository->rejectVendor($dto);

        return VendorRejectionResultDto::fromRow($row);
    }
    public function verifyIdentity(VerifyIdentityDto $dto): VendorIdentityVerificationResultDto
    {
        $row = $this->adminVendorRepository->verifyIdentity($dto);

        return VendorIdentityVerificationResultDto::fromRow($row);
    }
    public function getAll(VendorListFilterDto $filter): array
    {
        $result = $this->adminVendorRepository->getVendorsList($filter);

        $items = array_map(
            fn(object $row) => VendorListItemDto::fromRow($row),
            $result['items']
        );

        $totalPages = $filter->pageSize > 0
            ? (int) ceil($result['total'] / $filter->pageSize)
            : 0;

        return [
            'items' => $items,
            'pagination' => [
                'total' => $result['total'],
                'page' => $filter->pageNumber,
                'page_size' => $filter->pageSize,
                'total_pages' => $totalPages,
            ],
        ];
    }
}
