<?php

namespace App\Repositories\sql;

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
}