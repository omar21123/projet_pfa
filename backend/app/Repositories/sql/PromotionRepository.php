<?php

namespace App\Repositories\sql;

use App\DTOs\Promotion\CreatePromotionForCategoryDto;
use App\DTOs\Promotion\LookupItemDto;
use App\Exceptions\BusinessValidationException;
use App\Repositories\Interface\PromotionRepositoryInterface;
use Illuminate\Support\Facades\DB;
use App\DTOs\Promotion\CreatePromotionForProductDto;
use App\DTOs\Promotion\PromotionDto;
use App\DTOs\Promotion\PromotionResultDto;
use App\DTOs\Promotion\UpdatePromotionDto;

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
    public function createForProduct(CreatePromotionForProductDto $dto): PromotionDto
    {
        DB::select('CALL SP_CreatePromotionForProduct(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @promotionId, @success, @message)', [
            $dto->userPublicId,
            $dto->productId,
            $dto->name,
            $dto->description,
            $dto->promoCode,
            $dto->discountTypeCode,
            $dto->discountValue,
            $dto->maxDiscountAmount,
            $dto->minOrderAmount,
            $dto->usageLimitTotal,
            $dto->usageLimitPerUser,
            $dto->startDate,
            $dto->endDate,
        ]);

        $result = DB::selectOne('SELECT @promotionId AS promotionId, @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'Accès refusé') ? 403
                : (str_contains($result->message, 'introuvable') ? 404 : 422);
            throw new BusinessValidationException($result->message, $status);
        }

        return $this->getFullPromotionRow((int) $result->promotionId);
    }

    /**
     * Helper partagé : récupère une promotion avec ses libellés de lookup joints,
     * pour construire un PromotionDto complet.
     */
    private function getFullPromotionRow(int $promotionId): PromotionDto
    {
        $row = DB::selectOne('
        SELECT
            p.*,
            dt.Code AS DiscountTypeCode, dt.Label AS DiscountTypeLabel,
            st.Code AS ScopeTypeCode, st.Label AS ScopeTypeLabel,
            ps.Code AS StatusCode, ps.Label AS StatusLabel
        FROM Promotions p
        INNER JOIN PromotionDiscountTypes dt ON dt.DiscountTypeID = p.DiscountTypeID
        INNER JOIN PromotionScopeTypes st ON st.ScopeTypeID = p.ScopeTypeID
        INNER JOIN PromotionStatuses ps ON ps.StatusID = p.StatusID
        WHERE p.PromotionID = ?
    ', [$promotionId]);

        return PromotionDto::fromRow($row);
    }
    public function createForCategory(CreatePromotionForCategoryDto $dto): PromotionResultDto
    {
        DB::statement('CALL SP_CreatePromotionForCategory(?,?,?,?,?,?,?,?,?,?,?,?,?,@PromotionID,@Success,@Message)', [
            $dto->userPublicId,
            $dto->categoryId,
            $dto->name,
            $dto->description,
            $dto->promoCode,
            $dto->discountTypeCode,
            $dto->discountValue,
            $dto->maxDiscountAmount,
            $dto->minOrderAmount,
            $dto->usageLimitTotal,
            $dto->usageLimitPerUser,
            $dto->startDate,
            $dto->endDate,
        ]);

        $result = DB::selectOne('SELECT @PromotionID AS PromotionID, @Success AS Success, @Message AS Message');

        if (!$result->Success) {
            throw new \App\Exceptions\BusinessValidationException($result->Message, 422);
        }

        return PromotionResultDto::fromArray([
            'PromotionID' => $result->PromotionID,
            'Message'     => $result->Message,
        ]);
    }
    public function update(UpdatePromotionDto $dto): void
{
    DB::statement('CALL SP_UpdatePromotion(?,?,?,?,?,?,?,?,?,?,?,?,?,@Success,@Message)', [
        $dto->userPublicId,
        $dto->promotionId,
        $dto->name,
        $dto->description,
        $dto->promoCode,
        $dto->discountTypeCode,
        $dto->discountValue,
        $dto->maxDiscountAmount,
        $dto->minOrderAmount,
        $dto->usageLimitTotal,
        $dto->usageLimitPerUser,
        $dto->startDate,
        $dto->endDate,
    ]);

    $result = DB::selectOne('SELECT @Success AS Success, @Message AS Message');

    if (!$result->Success) {
        $status = str_contains($result->Message, 'introuvable') ? 404
                : (str_contains($result->Message, 'Accès refusé') ? 403 : 422);

        throw new \App\Exceptions\BusinessValidationException($result->Message, $status);
    }
}
}
