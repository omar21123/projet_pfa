<?php

namespace App\Repositories\sql;

use App\DTOs\Cart\AddCartItemDto;
use App\Repositories\Interface\CartRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;
use App\DTOs\Cart\RemoveCartItemDto;

use App\DTOs\Cart\CartItemInfoDto;
use App\DTOs\Cart\CartItemResponseDto;
use App\DTOs\Cart\CartPromotionInfoDto;
use App\DTOs\Cart\CombinationDetailInfoDto;

class CartRepository implements CartRepositoryInterface
{
    public function addItem(AddCartItemDto $dto): string
    {
        $result = DB::select('CALL SP_AddCartItem(?, ?, ?, ?, ?, @p_success, @p_message)', [
            $dto->userPublicId,
            $dto->productId,
            $dto->compositionId,
            $dto->quantity,
            $dto->unitPrice,
        ]);

        $out = DB::select('SELECT @p_success AS success, @p_message AS message')[0];

        if (! $out->success) {
            throw new BusinessValidationException($out->message);
        }

        return $out->message;
    }

    public function removeItem(RemoveCartItemDto $dto): string
    {
        DB::select('CALL SP_RemoveCartItem(?, ?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->productId,
            $dto->compositionId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'introuvable') ? 404 : 422;
            throw new BusinessValidationException($result->message, $status);
        }

        return $result->message;
    }


    public function getCartItemsInfo(string $userPublicId): array
    {
        $rows = DB::select('CALL SP_GetCartInformations(?, @success, @message)', [$userPublicId]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 404);
        }

        return array_map(fn($row) => CartItemResponseDto::fromInfoDto(CartItemInfoDto::fromRow($row)), $rows);
    }

    public function getCartItemPromotion(int $productId): ?CartPromotionInfoDto
    {
        $rows = DB::select('CALL SP_GetCartItemPromotion(?)', [$productId]);

        if (empty($rows)) {
            return null;
        }

        return CartPromotionInfoDto::fromRow($rows[0]);
    }

    public function getCombinationDetails(int $combinationId): array
    {
        $rows = DB::select('CALL SP_GetCombinationDetails(?)', [$combinationId]);

        return array_map(fn($row) => CombinationDetailInfoDto::fromRow($row), $rows);
    }
}
