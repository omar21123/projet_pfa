<?php

namespace App\Services;

use App\DTOs\Product\GetMostSoldProductsDto;
use App\DTOs\Product\GetNewProductsDto;
use App\DTOs\Product\GetPopularInYourRegionDto;
use App\DTOs\Product\ProductRecommendationsGroupedDto;
use App\Services\Interface\ProductRecommendationServiceInterface;
use App\Repositories\Interface\ProductRecommendationRepositoryInterface;

class ProductRecommendationService implements ProductRecommendationServiceInterface
{
    public function __construct(
        private ProductRecommendationRepositoryInterface $productRecommendationRepository,
        private IpWhoIsLocationService $whoisService
    ) {}

    public function getRecommendations(?string $userPublicId, int $limit = 20, ?int $categoryId = null , ?string $IpAddress = null): ProductRecommendationsGroupedDto
    {
        // TODO: une fois getMostWishedProducts()/getTrendingProducts()/
        // getRecentlyAddedProducts() implémentées côté repository, décider
        // ici comment les combiner — DTO groupé (approche actuelle) ou
        // mélange pondéré en une seule liste plate.

        $mostSold = $this->productRecommendationRepository->getMostSoldProducts(
            GetMostSoldProductsDto::fromArray([
                'userPublicId' => $userPublicId,
                'limit'        => $limit,
                'categoryId'   => $categoryId,
            ])
        );

        $mostViewed = $this->productRecommendationRepository->getMostViewedProducts(
            GetMostSoldProductsDto::fromArray([
                'userPublicId' => $userPublicId,
                'limit'        => $limit,
                'categoryId'   => $categoryId,
            ])
        );

        $promotions = $this->productRecommendationRepository->getPromotionsProducts(
            GetMostSoldProductsDto::fromArray([
                'userPublicId' => $userPublicId,
                'limit'        => $limit,
                'categoryId'   => $categoryId,
            ])
        );
        $trending = $this->productRecommendationRepository->getTrendingProducts(
            GetMostSoldProductsDto::fromArray([
                'userPublicId' => $userPublicId,
                'limit'        => $limit,
                'categoryId'   => $categoryId,
            ])
        );
        $fromYourLastActivity = $this->productRecommendationRepository->getFromYourLastActivityProducts(
            GetMostSoldProductsDto::fromArray([
                'userPublicId' => $userPublicId,
                'limit'        => $limit,
                'categoryId'   => $categoryId,
            ]) ,
            $IpAddress ?? null
        );
        $region = $this->whoisService->locate($IpAddress ?? null);
        $popularInYourRegion = $this->productRecommendationRepository->getPopularInYourRegion(
            GetPopularInYourRegionDto::fromArray([
                'userPublicId' => $userPublicId,
                'countryCode'  => $region?->countryCode,
                'region'       => $region?->region,
                'limit'        => $limit,
                'categoryId'   => $categoryId,
            ])
        );
         $dto = GetNewProductsDto::fromArray([
        'userPublicId' => $userPublicId,
        'daysBack'     => 7,
        'limit'        => $limit,
        'categoryId'   => $categoryId,
    ]);

    $newestproducts = $this->productRecommendationRepository->getNewProducts($dto);
        return new ProductRecommendationsGroupedDto(
            mostSold: array_map(fn($dto) => $dto->toArray(), $mostSold),
            mostViewed: array_map(fn($dto) => $dto->toArray(), $mostViewed),
            promotions: array_map(fn($dto) => $dto->toArray(), $promotions),
            trending: array_map(fn($dto) => $dto->toArray(), $trending),
            popularInYourRegion: array_map(fn($dto) => $dto->toArray(), $popularInYourRegion),
            fromYourLastActivity: array_map(fn($dto) => $dto->toArray(), $fromYourLastActivity),
            newestproducts: array_map(fn($dto) => $dto->toArray(), $newestproducts)
        );
    }
}