<?php

namespace App\Services\Interface;

use App\DTOs\Product\Stats\IncrementRegionalProductStatDto;

interface ProductStatsServiceInterface
{
    public function incrementViewCount(IncrementRegionalProductStatDto $dto): void;
    public function incrementPurchaseCount(IncrementRegionalProductStatDto $dto): void;
}