<?php

namespace App\Services;

use App\DTOs\Product\GetMostSoldProductsDto;
use App\DTOs\Product\ProductRecommendationsGroupedDto;
use App\Services\Interface\ProductRecommendationServiceInterface;
use App\Repositories\Interface\ProductRecommendationRepositoryInterface;

class ProductRecommendationService implements ProductRecommendationServiceInterface
{
    public function __construct(
        private ProductRecommendationRepositoryInterface $productRecommendationRepository,
    ) {}

   public function getRecommendations(?string $userPublicId, int $limit = 20): ProductRecommendationsGroupedDto
{
    // TODO: une fois getMostViewedProducts()/getMostWishedProducts()/
    // getTrendingProducts()/getRecentlyAddedProducts() implémentées côté
    // repository, décider ici comment les combiner :
    // - soit un DTO groupé (ce qu'on fait ici) exposant chaque source séparément,
    //   comme pour les produits similaires ;
    // - soit un mélange pondéré en une seule liste plate.
    // Pour l'instant, seule la source "plus vendus" est branchée.

    $mostSold = $this->productRecommendationRepository->getMostSoldProducts(
        GetMostSoldProductsDto::fromArray([
            'userPublicId' => $userPublicId,
            'limit'        => $limit,
        ])
    );
    $mostViewed = $this->productRecommendationRepository->getMostViewedProducts(
        GetMostSoldProductsDto::fromArray([
            'userPublicId' => $userPublicId,
            'limit'        => $limit,
        ])
    );

    return new ProductRecommendationsGroupedDto(
        mostSold: array_map(fn($dto) => $dto->toArray(), $mostSold),
        mostViewed: array_map(fn($dto) => $dto->toArray(), $mostViewed),
        promotions: [],
    );
}
}