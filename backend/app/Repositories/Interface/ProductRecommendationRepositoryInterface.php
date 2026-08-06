<?php

namespace App\Repositories\Interface;

use App\DTOs\Product\GetMostSoldProductsDto;
use App\DTOs\Product\GetNewProductsDto;
use App\DTOs\Product\GetPopularInYourRegionDto;

interface ProductRecommendationRepositoryInterface
{
    /**
     * @return \App\DTOs\Product\ProductItemDto[]
     */
    public function getMostSoldProducts(GetMostSoldProductsDto $dto): array;
    public function getMostViewedProducts(GetMostSoldProductsDto $dto): array;
    public function getPromotionsProducts(GetMostSoldProductsDto $dto): array;
    public function getTrendingProducts(GetMostSoldProductsDto $dto): array;
    public function getFromYourLastActivityProducts(GetMostSoldProductsDto $dto ,?string $IpAddress): array;
    public function getPopularInYourRegion(GetPopularInYourRegionDto $dto): array;
    public function getNewProducts(GetNewProductsDto $dto): array;

}
