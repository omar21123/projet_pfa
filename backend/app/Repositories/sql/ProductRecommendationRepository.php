<?php

namespace App\Repositories\sql;

use App\DTOs\Product\GetMostSoldProductsDto;
use App\DTOs\Product\GetNewProductsDto;
use App\DTOs\Product\GetPopularInYourRegionDto;
use App\DTOs\Product\ProductItemDto;
use App\Repositories\Interface\ProductRecommendationRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;

class ProductRecommendationRepository implements ProductRecommendationRepositoryInterface
{
    public function getMostSoldProducts(GetMostSoldProductsDto $dto): array
    {
        $rows = DB::select('CALL SP_GetMostSoldProducts(?, ?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->limit,
            $dto->categoryId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        return array_map(fn($row) => ProductItemDto::fromRow($row), $rows);
    }

    public function getMostViewedProducts(GetMostSoldProductsDto $dto): array
    {
        $rows = DB::select('CALL SP_GetMostViewedProducts(?, ?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->limit,
            $dto->categoryId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        return array_map(fn($row) => ProductItemDto::fromRow($row), $rows);
    }
    public function getPromotionsProducts(GetMostSoldProductsDto $dto): array
    {
        $rows = DB::select('CALL SP_GetMostPromotedProducts(?, ?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->limit,
            $dto->categoryId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        return array_map(fn($row) => ProductItemDto::fromRow($row), $rows);
    }
    public function getTrendingProducts(GetMostSoldProductsDto $dto): array
    {
        $rows = DB::select('CALL SP_GetTrendingProducts(?, ?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->limit,
            $dto->categoryId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        return array_map(fn($row) => ProductItemDto::fromRow($row), $rows);
    }
    public function getFromYourLastActivityProducts(GetMostSoldProductsDto $dto, ?string $IpAddress): array
    {
        $rows = DB::select('CALL SP_GetLastActivityProducts(?, ?, ?, ?,@success, @message)', [
            $dto->userPublicId,
            $IpAddress,
            $dto->limit,
            $dto->categoryId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        return array_map(fn($row) => ProductItemDto::fromRow($row), $rows);
    }
    public function getNewProducts(GetNewProductsDto $dto): array
    {
        $rows = DB::select('CALL SP_GetNewProducts(?, ?, ?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->daysBack,
            $dto->limit,
            $dto->categoryId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        return array_map(fn($row) => ProductItemDto::fromRow($row), $rows);
    }
    public function getPopularInYourRegion(GetPopularInYourRegionDto $dto): array
    {
        $rows = DB::select('CALL SP_GetPopularInYourRegion(?, ?, ?, ?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->countryCode,
            $dto->region,
            $dto->limit,
            $dto->categoryId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        return array_map(fn($row) => ProductItemDto::fromRow($row), $rows);
    }
}
