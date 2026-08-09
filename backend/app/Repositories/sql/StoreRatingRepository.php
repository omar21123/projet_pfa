<?php
// App\Repositories\sql\StoreRatingRepository
namespace App\Repositories\sql;

use App\DTOs\Vendor\StoreRatingDto;
use App\Repositories\Interface\StoreRatingRepositoryInterface;
use Illuminate\Support\Facades\DB;

class StoreRatingRepository implements StoreRatingRepositoryInterface
{
    public function insert(string $userPublicID, int $vendorProfileID, int $rating, ?string $comment): bool
    {
        DB::statement('SET @v_Success = FALSE');
        DB::statement('SET @v_Message = ""');

        DB::statement('CALL SP_InsertStoreRating(?, ?, ?, ?, @v_Success, @v_Message)', [
            $userPublicID,
            $vendorProfileID,
            $rating,
            $comment,
        ]);

        $output = DB::selectOne('SELECT @v_Success AS Success, @v_Message AS Message');

        if (!$output->Success) {
            throw new \App\Exceptions\BusinessValidationException($output->Message, 422);
        }

        return true;
    }

    public function update(string $userPublicID, int $vendorProfileID, int $rating, ?string $comment): bool
    {
        DB::statement('SET @v_Success = FALSE');
        DB::statement('SET @v_Message = ""');

        DB::statement('CALL SP_UpdateStoreRating(?, ?, ?, ?, @v_Success, @v_Message)', [
            $userPublicID,
            $vendorProfileID,
            $rating,
            $comment,
        ]);

        $output = DB::selectOne('SELECT @v_Success AS Success, @v_Message AS Message');

        if (!$output->Success) {
            throw new \App\Exceptions\BusinessValidationException($output->Message, 422);
        }

        return true;
    }

    public function delete(string $userPublicID, int $vendorProfileID): bool
    {
        DB::statement('SET @v_Success = FALSE');
        DB::statement('SET @v_Message = ""');

        DB::statement('CALL SP_DeleteStoreRating(?, ?, @v_Success, @v_Message)', [
            $userPublicID,
            $vendorProfileID,
        ]);

        $output = DB::selectOne('SELECT @v_Success AS Success, @v_Message AS Message');

        if (!$output->Success) {
            throw new \App\Exceptions\BusinessValidationException($output->Message, 422);
        }

        return true;
    }

    public function getByVendor(int $vendorProfileID, int $pageNumber, int $pageSize): array
    {
        DB::statement('SET @v_TotalCount    = 0');
        DB::statement('SET @v_AverageRating = 0');
        DB::statement('SET @v_Success       = FALSE');
        DB::statement('SET @v_Message       = ""');

        $results = DB::select(
            'CALL SP_GetStoreRatings(?, ?, ?, @v_TotalCount, @v_AverageRating, @v_Success, @v_Message)',
            [$vendorProfileID, $pageNumber, $pageSize]
        );

        $output = DB::selectOne(
            'SELECT @v_Success AS Success, @v_Message AS Message, @v_TotalCount AS TotalCount, @v_AverageRating AS AverageRating'
        );

        if (!$output->Success) {
            throw new \App\Exceptions\BusinessValidationException($output->Message, 422);
        }

        return [
            'data'          => array_map(fn($row) => StoreRatingDto::fromRow($row), $results),
            'total'         => (int)   $output->TotalCount,
            'averageRating' => (float) $output->AverageRating,
            'page'          => $pageNumber,
            'pageSize'      => $pageSize,
            'totalPages'    => (int) ceil($output->TotalCount / $pageSize),
        ];
    }
}