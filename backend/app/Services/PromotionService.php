<?php

namespace App\Services;

use App\DTOs\Promotion\CreatePromotionForCategoryDto;
use App\DTOs\Promotion\LookupItemDto;
use App\Repositories\Interface\PromotionRepositoryInterface;
use App\Services\Interface\PromotionServiceInterface;
use App\DTOs\Promotion\CreatePromotionForProductDto;
use App\DTOs\Promotion\PromotionDto;
use App\DTOs\Promotion\PromotionResultDto;

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
    public function createForProduct(CreatePromotionForProductDto $dto): PromotionDto
    {
        return $this->promotionRepository->createForProduct($dto);
    }
    public function createForCategory(CreatePromotionForCategoryDto $dto): PromotionResultDto
    {
        return $this->promotionRepository->createForCategory($dto);
    }
}
