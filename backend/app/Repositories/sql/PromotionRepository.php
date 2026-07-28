<?php

namespace App\Repositories\sql;

use App\DTOs\Promotion\LookupItemDto;
use App\Exceptions\BusinessValidationException;
use App\Repositories\Interface\PromotionRepositoryInterface;
use Illuminate\Support\Facades\DB;

class PromotionRepository implements PromotionRepositoryInterface
{
    public function getDiscountTypes(): array
    {
        $rows = DB::select('CALL SP_GetPromotionDiscountTypes()');
        return array_map(fn($r) => LookupItemDto::fromRow($r, 'DiscountTypeID'), $rows);
    }

    public function getScopeTypes(): array
    {
        $rows = DB::select('CALL SP_GetPromotionScopeTypes()');
        return array_map(fn($r) => LookupItemDto::fromRow($r, 'ScopeTypeID'), $rows);
    }

    public function getStatuses(): array
    {
        $rows = DB::select('CALL SP_GetPromotionStatuses()');
        return array_map(fn($r) => LookupItemDto::fromRow($r, 'StatusID'), $rows);
    }
}