<?php

namespace App\Repositories\sql;

use App\DTOs\Product\Stats\IncrementRegionalProductStatDto;
use App\Repositories\Interface\ProductStatsRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;

class ProductStatsRepository implements ProductStatsRepositoryInterface
{
    public function incrementViewCount(IncrementRegionalProductStatDto $dto): void
    {
        DB::select('CALL SP_IncrementRegionalProductViewCount(?, ?, ?, @success, @message)', [
            $dto->productId,
            $dto->countryCode,
            $dto->region,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'introuvable') ? 404 : 422;
            throw new BusinessValidationException($result->message, $status);
        }
    }

    public function incrementPurchaseCount(IncrementRegionalProductStatDto $dto): void
    {
        DB::select('CALL SP_IncrementRegionalProductPurchaseCount(?, ?, ?, @success, @message)', [
            $dto->productId,
            $dto->countryCode,
            $dto->region,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'introuvable') ? 404 : 422;
            throw new BusinessValidationException($result->message, $status);
        }
    }
}