<?php

namespace App\Repositories\Interface;

use App\DTOs\Product\GetMostSoldProductsDto;

interface ProductRecommendationRepositoryInterface
{
    /**
     * @return \App\DTOs\Product\ProductItemDto[]
     */
    public function getMostSoldProducts(GetMostSoldProductsDto $dto): array;
    public function getMostViewedProducts(GetMostSoldProductsDto $dto): array;
    // TODO: getMostWishedProducts() — tri par COUNT(WishListItems), même forme
    // de SELECT que getMostSoldProducts() mais ORDER BY TotalWishlist DESC.

    // TODO: getTrendingProducts() — une fois RegionalProductStats.TrendScore
    // effectivement calculé (voir dette technique du module ProductStats).

    // TODO: getRecentlyAddedProducts() — ORDER BY p.CreatedAt DESC, filtré sur
    // les produits actifs/non bloqués.
}
