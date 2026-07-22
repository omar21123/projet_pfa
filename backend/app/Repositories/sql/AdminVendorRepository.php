<?php

namespace App\Repositories\sql;

use App\DTOs\Admin\VendorListFilterDto;
use App\DTOs\Admin\VerifyIdentityDto;
use App\Repositories\Interface\AdminVendorRepositoryInterface;
use Illuminate\Support\Facades\DB;
use App\DTOs\Admin\ApproveVendorDto;
use App\Exceptions\VendorApprovalException;
use Illuminate\Database\QueryException;
use App\DTOs\Admin\RejectVendorDto;
use App\DTOs\Admin\ResetVendorToPendingDto;


class AdminVendorRepository implements AdminVendorRepositoryInterface
{
    public function resetVendorToPending(ResetVendorToPendingDto $dto): object
    {
        $result = DB::select('CALL SP_ResetVendorToPending(?,?,?)', [
            $dto->vendorProfileId,
            $dto->verifiedBy,
            $dto->notes,
        ]);

        if (empty($result)) {
            throw new \RuntimeException('Vendor profile not found.');
        }

        return $result[0];
    }
    public function approveVendor(ApproveVendorDto $dto): object
    {
        try {
            $result = DB::select('CALL SP_ApproveVendor(?,?,?)', [
                $dto->vendorProfileId,
                $dto->verifiedBy,
                $dto->verificationNotes,
            ]);
        } catch (QueryException $e) {
            // MySQL error code 1644 = custom SIGNAL SQLSTATE '45000'
            if ((int) $e->errorInfo[1] === 1644) {
                throw new VendorApprovalException($e->errorInfo[2] ?? 'Vendor cannot be approved.');
            }

            throw $e;
        }

        if (empty($result)) {
            throw new \RuntimeException('Vendor profile not found.');
        }

        return $result[0];
    }
    public function rejectVendor(RejectVendorDto $dto): object
    {
        $result = DB::select('CALL SP_RejectVendor(?,?,?)', [
            $dto->vendorProfileId,
            $dto->verifiedBy,
            $dto->rejectionNotes,
        ]);

        if (empty($result)) {
            throw new \RuntimeException('Vendor profile not found.');
        }

        return $result[0];
    }
    public function verifyIdentity(VerifyIdentityDto $dto): object
    {
        $result = DB::select('CALL SP_VerifyIdentity(?,?,?)', [
            $dto->vendorProfileId,
            $dto->verifiedBy,
            $dto->verificationNotes,
        ]);

        if (empty($result)) {
            throw new \RuntimeException('Vendor profile not found.');
        }

        return $result[0];
    }

    public function getVendorsList(VendorListFilterDto $filter): array
    {
        $countResult = DB::select('CALL SP_GetVendorsCount(?,?,?)', [
            $filter->search,
            $filter->verificationStatus,
            $filter->isSuspended,
        ]);

        $total = (int) ($countResult[0]->TotalCount ?? 0);

        $rows = DB::select('CALL SP_GetVendorsList(?,?,?,?,?)', [
            $filter->search,
            $filter->verificationStatus,
            $filter->isSuspended,
            $filter->pageNumber,
            $filter->pageSize,
        ]);

        return [
            'total' => $total,
            'items' => $rows,
        ];
    }
}
