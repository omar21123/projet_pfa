<?php

namespace App\Repositories\sql;

use App\DTOs\Product\GetMostSoldProductsDto;
use App\DTOs\Product\ProductItemDto;
use App\Repositories\Interface\ProductRecommendationRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;

class ProductRecommendationRepository implements ProductRecommendationRepositoryInterface
{
    public function getMostSoldProducts(GetMostSoldProductsDto $dto): array
    {
        $rows = DB::select('CALL SP_GetMostSoldProducts(?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->limit,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        return array_map(fn($row) => ProductItemDto::fromRow($row), $rows);
    }
    public function getMostViewedProducts(GetMostSoldProductsDto $dto): array
    {
        $rows = DB::select('CALL SP_GetMostViewedProducts(?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->limit,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        return array_map(fn($row) => ProductItemDto::fromRow($row), $rows);
    }
}
