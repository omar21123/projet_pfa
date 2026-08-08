<?php

namespace App\Repositories\Interface;

use App\DTOs\Product\Stats\IncrementRegionalProductStatDto;

interface ProductStatsRepositoryInterface
{
    public function incrementViewCount(IncrementRegionalProductStatDto $dto): void;
    public function incrementPurchaseCount(IncrementRegionalProductStatDto $dto): void;
}