<?php

namespace App\Services;

use App\DTOs\Promotion\CreatePromotionForCategoryDto;
use App\DTOs\Promotion\LookupItemDto;
use App\Repositories\Interface\PromotionRepositoryInterface;
use App\Services\Interface\PromotionServiceInterface;
use App\DTOs\Promotion\CreatePromotionForProductDto;
use App\DTOs\Promotion\PromotionDto;
use App\DTOs\Promotion\PromotionResultDto;
use App\DTOs\Promotion\UpdatePromotionDto;
use App\DTOs\Promotion\DeletePromotionDto;
use App\DTOs\Promotion\GetPromotionsByProductDto;
use App\DTOs\Promotion\PromotionIdActionDto;



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
    public function update(UpdatePromotionDto $dto): void
    {
        $this->promotionRepository->update($dto);
    }

    public function softDelete(DeletePromotionDto $dto): void
    {
        $this->promotionRepository->softDelete($dto);
    }
    public function deactivate(PromotionIdActionDto $dto): void
    {
        $this->promotionRepository->deactivate($dto);
    }
    public function getById(PromotionIdActionDto $dto): PromotionDto
    {
        return $this->promotionRepository->getById($dto);
    }
    public function getByProduct(GetPromotionsByProductDto $dto): array
    {
        return $this->promotionRepository->getByProduct($dto);
    }
}
