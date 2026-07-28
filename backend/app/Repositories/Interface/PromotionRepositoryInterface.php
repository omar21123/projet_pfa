<?php

namespace App\Repositories\Interface;

use App\DTOs\Promotion\LookupItemDto;

interface PromotionRepositoryInterface
{
    /** @return LookupItemDto[] */
    public function getDiscountTypes(): array;

    /** @return LookupItemDto[] */
    public function getScopeTypes(): array;

    /** @return LookupItemDto[] */
    public function getStatuses(): array;
}