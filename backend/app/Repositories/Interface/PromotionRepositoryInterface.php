<?php

namespace App\Repositories\Interface;

use App\DTOs\Promotion\CreatePromotionForCategoryDto;
use App\DTOs\Promotion\LookupItemDto;
use App\DTOs\Promotion\CreatePromotionForProductDto;
use App\DTOs\Promotion\PromotionDto;
use App\DTOs\Promotion\PromotionResultDto;
use App\DTOs\Promotion\UpdatePromotionDto;
use App\DTOs\Promotion\DeletePromotionDto;
use App\DTOs\Promotion\PromotionIdActionDto;
use App\DTOs\Promotion\GetPromotionsByProductDto;
use App\DTOs\Promotion\GetPromotionsByCategoryDto;
// PromotionRepositoryInterface
use App\DTOs\Promotion\GetAllPromotionsDto;


interface PromotionRepositoryInterface
{
    /** @return LookupItemDto[] */
    public function getDiscountTypes(): array;

    /** @return LookupItemDto[] */
    public function getScopeTypes(): array;

    /** @return LookupItemDto[] */
    public function getStatuses(): array;

    public function createForProduct(CreatePromotionForProductDto $dto): PromotionDto;
    public function createForCategory(CreatePromotionForCategoryDto $dto): PromotionResultDto;
    public function update(UpdatePromotionDto $dto): void;
    public function softDelete(DeletePromotionDto $dto): void;
    public function deactivate(PromotionIdActionDto $dto): void;
    public function getById(PromotionIdActionDto $dto): PromotionDto;


    /** @return PromotionDto[] */
    public function getByProduct(GetPromotionsByProductDto $dto): array;

    /** @return CategoryAllPromotionDto[] */
    public function getByCategory(GetPromotionsByCategoryDto $dto): array;
/** @return array{items: AllPromotionDto[], page: int, pageSize: int, hasMore: bool} */
public function getAll(GetAllPromotionsDto $dto): array;
}
