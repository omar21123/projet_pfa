<?php

namespace App\Services\Interface;

use App\DTOs\Product\LoadMoreProductsQueryDto;
use App\DTOs\Product\PaginatedProductItemResponseDto;
use App\DTOs\Product\ProductRecommendationsGroupedDto;

interface ProductRecommendationServiceInterface
{
    public function getRecommendations(?string $userPublicId, int $limit = 20, ?int $categoryId = null , ?string $IpAddress = null): ProductRecommendationsGroupedDto;
    public function loadMoreMostSoldProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
    public function loadMoreMostViewedProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
    public function loadMoreMostPromotedProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
    public function loadMoreTrendingProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
    public function loadMoreLastActivityProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
    public function loadMorePopularInYourRegion(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
    public function loadMoreNewProducts(LoadMoreProductsQueryDto $dto): PaginatedProductItemResponseDto;
}