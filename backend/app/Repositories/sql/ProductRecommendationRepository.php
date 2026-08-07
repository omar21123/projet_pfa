<?php

namespace App\Repositories\sql;

use App\DTOs\Product\GetMostSoldProductsDto;
use App\DTOs\Product\GetNewProductsDto;
use App\DTOs\Product\GetPopularInYourRegionDto;
use App\DTOs\Product\LoadMoreProductsQueryDto;
use App\DTOs\Product\PaginatedProductItemResponseDto;
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
    public function loadMoreMostSoldProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto
    {
        $rows = DB::select('CALL SP_LoadMoreMostSoldProducts(?, ?, ?, ?, @totalCount, @success, @message)', [
            $dto->userPublicId,
            $dto->categoryId,
            $dto->pageNumber,
            $dto->pageSize,
        ]);

        return $this->mapPaginatedResult($rows, $dto);
    }

    public function loadMoreMostViewedProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto
    {
        $rows = DB::select('CALL SP_LoadMoreMostViewedProducts(?, ?, ?, ?, @totalCount, @success, @message)', [
            $dto->userPublicId,
            $dto->categoryId,
            $dto->pageNumber,
            $dto->pageSize,
        ]);

        return $this->mapPaginatedResult($rows, $dto);
    }

    public function loadMoreMostPromotedProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto
    {
        $rows = DB::select('CALL SP_LoadMoreMostPromotedProducts(?, ?, ?, ?, @totalCount, @success, @message)', [
            $dto->userPublicId,
            $dto->categoryId,
            $dto->pageNumber,
            $dto->pageSize,
        ]);

        return $this->mapPaginatedResult($rows, $dto);
    }

    public function loadMoreTrendingProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto
    {
        $rows = DB::select('CALL SP_LoadMoreTrendingProducts(?, ?, ?, ?, @totalCount, @success, @message)', [
            $dto->userPublicId,
            $dto->categoryId,
            $dto->pageNumber,
            $dto->pageSize,
        ]);

        return $this->mapPaginatedResult($rows, $dto);
    }

    public function loadMoreLastActivityProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto
    {
        $rows = DB::select('CALL SP_LoadMoreLastActivityProducts(?, ?, ?, ?, ?, @totalCount, @success, @message)', [
            $dto->userPublicId,
            $dto->ipAddress,
            $dto->categoryId,
            $dto->pageNumber,
            $dto->pageSize,
        ]);

        return $this->mapPaginatedResult($rows, $dto);
    }

    public function loadMorePopularInYourRegion(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto
    {
        $rows = DB::select('CALL SP_LoadMorePopularInYourRegion(?, ?, ?, ?, ?, ?, @totalCount, @success, @message)', [
            $dto->userPublicId,
            $dto->countryCode,
            $dto->region,
            $dto->categoryId,
            $dto->pageNumber,
            $dto->pageSize,
        ]);

        return $this->mapPaginatedResult($rows, $dto, filterNullProductId: true);
    }

    public function loadMoreNewProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto
    {
        $rows = DB::select('CALL SP_LoadMoreNewProducts(?, ?, ?, ?, ?, @totalCount, @success, @message)', [
            $dto->userPublicId,
            $dto->daysBack,
            $dto->categoryId,
            $dto->pageNumber,
            $dto->pageSize,
        ]);

        return $this->mapPaginatedResult($rows, $dto);
    }

    /**
     * Toutes les SP LoadMore partagent le même contrat de retour
     * (OUT totalCount/success/message + un resultset de lignes produit) —
     * on centralise le mapping ici pour ne pas le dupliquer 7 fois.
     */
    private function mapPaginatedResult(array $rows, LoadMoreProductsQueryDto $dto, bool $filterNullProductId = false): PaginatedProductItemResponseDto
    {
        $result = DB::selectOne('SELECT @totalCount AS totalCount, @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        $items = $filterNullProductId
            ? array_values(array_filter(
                array_map(fn($row) => $row->ProductID !== null ? ProductItemDto::fromRow($row) : null, $rows)
            ))
            : array_map(fn($row) => ProductItemDto::fromRow($row), $rows);

        return new PaginatedProductItemResponseDto(
            items: $items,
            total: (int) $result->totalCount,
            page: $dto->pageNumber,
            pageSize: $dto->pageSize,
        );
    }
}
