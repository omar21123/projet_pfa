<?php

namespace App\Repositories\sql;

use App\DTOs\Product\ProductItemDto;
use App\DTOs\Vendor\VendorProfileResponseDto;
use App\DTOs\Vendor\VendorPublicProfileResponseDto;
use App\Repositories\Interface\VendorRepositoryInterface;
use Illuminate\Support\Facades\DB;

class VendorRepository implements VendorRepositoryInterface
{
    public function findByUserId(int $userId): ?object
    {
        $row = DB::selectOne("
            SELECT *
            FROM VendorProfiles
            WHERE UserID = ?
        ", [$userId]);

        return $row ?: null;
    }
    public function findByProductId(int $productId): ?VendorProfileResponseDto
    {
        DB::statement('SET @v_Success = FALSE');
        DB::statement('SET @v_Message = ""');

        $results = DB::select('CALL sp_GetVendorProfile(?, @v_Success, @v_Message)', [
            $productId,
        ]);

        $output = DB::selectOne('SELECT @v_Success AS Success, @v_Message AS Message');

        if (!$output->Success || empty($results)) {
            return null;
        }

        return VendorProfileResponseDto::fromRow($results[0]);
    }
    public function getVendorProducts(
        int     $vendorProfileID,
        ?string $userPublicID,
        ?int    $categoryID,
        int     $pageNumber,
        int     $pageSize
    ): array {
        DB::statement('SET @v_TotalCount = 0');
        DB::statement('SET @v_Success    = FALSE');
        DB::statement('SET @v_Message    = ""');

        $results = DB::select(
            'CALL SP_GetVendorProducts(?, ?, ?, ?, ?, @v_TotalCount, @v_Success, @v_Message)',
            [$vendorProfileID, $userPublicID, $categoryID, $pageNumber, $pageSize]
        );

        $output = DB::selectOne(
            'SELECT @v_Success AS Success, @v_Message AS Message, @v_TotalCount AS TotalCount'
        );

        if (!$output->Success) {
            return [
                'data'       => [],
                'total'      => 0,
                'page'       => $pageNumber,
                'pageSize'   => $pageSize,
                'totalPages' => 0,
            ];
        }

        return [
            'data'       => array_map(
                fn($row) => ProductItemDto::fromRow($row),
                $results
            ),
            'total'      => (int) $output->TotalCount,
            'page'       => $pageNumber,
            'pageSize'   => $pageSize,
            'totalPages' => (int) ceil($output->TotalCount / $pageSize),
        ];
    }
    public function getPublicProfile(int $vendorProfileID): ?VendorPublicProfileResponseDto
    {
        DB::statement('SET @v_Success = FALSE');
        DB::statement('SET @v_Message = ""');

        $results = DB::select('CALL sp_GetVendorPublicProfile(?, @v_Success, @v_Message)', [
            $vendorProfileID,
        ]);

        $output = DB::selectOne('SELECT @v_Success AS Success, @v_Message AS Message');

        if (!$output->Success || empty($results)) {
            return null;
        }

        return VendorPublicProfileResponseDto::fromRow($results[0]);
    }
}
