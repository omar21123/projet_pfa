<?php

namespace App\Repositories\sql;

use App\DTOs\Vendor\VendorProfileResponseDto;
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
}
