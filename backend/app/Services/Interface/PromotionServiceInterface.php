<?php

namespace App\Services\Interface;

use App\DTOs\Promotion\LookupItemDto;

interface PromotionServiceInterface
{
    /** @return LookupItemDto[] */
    public function getDiscountTypes(): array;

    /** @return LookupItemDto[] */
    public function getScopeTypes(): array;

    /** @return LookupItemDto[] */
    public function getStatuses(): array;
}