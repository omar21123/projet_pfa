<?php

namespace App\Services\Interface;

use App\DTOs\Promotion\CreatePromotionForCategoryDto;
use App\DTOs\Promotion\LookupItemDto;
use App\DTOs\Promotion\CreatePromotionForProductDto;
use App\DTOs\Promotion\PromotionDto;
use App\DTOs\Promotion\PromotionResultDto;
use App\DTOs\Promotion\UpdatePromotionDto;
use App\DTOs\Promotion\DeletePromotionDto;
use App\DTOs\Promotion\GetPromotionsByProductDto;
use App\DTOs\Promotion\PromotionIdActionDto;

interface PromotionServiceInterface
{
    /** @return LookupItemDto[] */
    public function getDiscountTypes(): array;

    /** @return LookupItemDto[] */
    public function getScopeTypes(): array;

    /** @return LookupItemDto[] */
    public function getStatuses(): array;
    public function createForProduct(CreatePromotionForProductDto $dto): PromotionDto;
    // App\Services\Interface\PromotionRepositoryInterface (or wherever it lives)
    public function createForCategory(CreatePromotionForCategoryDto $dto): PromotionResultDto;
    public function update(UpdatePromotionDto $dto): void;

    public function softDelete(DeletePromotionDto $dto): void;
    public function deactivate(PromotionIdActionDto $dto): void;
    public function getById(PromotionIdActionDto $dto): PromotionDto;
    /** @return PromotionDto[] */
    public function getByProduct(GetPromotionsByProductDto $dto): array;
}
