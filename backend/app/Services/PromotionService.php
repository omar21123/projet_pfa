<?php

namespace App\Services;

use App\DTOs\Promotion\LookupItemDto;
use App\Repositories\Interface\PromotionRepositoryInterface;
use App\Services\Interface\PromotionServiceInterface;

class PromotionService implements PromotionServiceInterface
{
    public function __construct(
        protected PromotionRepositoryInterface $promotionRepository
    ) {}

    public function getDiscountTypes(): array
    {
        return $this->promotionRepository->getDiscountTypes();
    }

    public function getScopeTypes(): array
    {
        return $this->promotionRepository->getScopeTypes();
    }

    public function getStatuses(): array
    {
        return $this->promotionRepository->getStatuses();
    }
}