<?php

namespace App\Services\Interface;

use App\DTOs\Product\ProductRecommendationsGroupedDto;

interface ProductRecommendationServiceInterface
{
    public function getRecommendations(?string $userPublicId, int $limit = 20): ProductRecommendationsGroupedDto;
}