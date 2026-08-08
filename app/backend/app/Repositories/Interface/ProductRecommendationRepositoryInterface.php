<?php

namespace App\Repositories\Interface;

use App\DTOs\Product\GetMostSoldProductsDto;
use App\DTOs\Product\GetNewProductsDto;
use App\DTOs\Product\GetPopularInYourRegionDto;
use App\DTOs\Product\LoadMoreProductsQueryDto;
use App\DTOs\Product\PaginatedProductItemResponseDto;

interface ProductRecommendationRepositoryInterface
{
    /**
     * @return \App\DTOs\Product\ProductItemDto[]
     */
    public function getMostSoldProducts(GetMostSoldProductsDto $dto): array;
    public function getMostViewedProducts(GetMostSoldProductsDto $dto): array;
    public function getPromotionsProducts(GetMostSoldProductsDto $dto): array;
    public function getTrendingProducts(GetMostSoldProductsDto $dto): array;
    public function getFromYourLastActivityProducts(GetMostSoldProductsDto $dto, ?string $IpAddress): array;
    public function getPopularInYourRegion(GetPopularInYourRegionDto $dto): array;
    public function getNewProducts(GetNewProductsDto $dto): array;
    public function loadMoreMostSoldProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
    public function loadMoreMostViewedProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
    public function loadMoreMostPromotedProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
    public function loadMoreTrendingProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
    public function loadMoreLastActivityProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
    public function loadMorePopularInYourRegion(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
    public function loadMoreNewProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
}
