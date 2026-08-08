<?php

namespace App\Services;

use App\DTOs\Product\Stats\IncrementRegionalProductStatDto;
use App\Services\Interface\ProductStatsServiceInterface;
use App\Repositories\Interface\ProductStatsRepositoryInterface;

class ProductStatsService implements ProductStatsServiceInterface
{
    public function __construct(
        private ProductStatsRepositoryInterface $productStatsRepository,
    ) {}

    public function incrementViewCount(IncrementRegionalProductStatDto $dto): void
    {
        $this->productStatsRepository->incrementViewCount($dto);
    }

    public function incrementPurchaseCount(IncrementRegionalProductStatDto $dto): void
    {
        $this->productStatsRepository->incrementPurchaseCount($dto);
    }
}