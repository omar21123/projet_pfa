<?php

namespace App\Repositories\sql;

use App\DTOs\Cart\AddCartItemDto;
use App\Repositories\Interface\CartRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;
use App\DTOs\Cart\RemoveCartItemDto;
use Illuminate\Support\Facades\Log;  // ← ADD THIS
use App\DTOs\Cart\CartItemInfoDto;
use App\DTOs\Cart\CartItemResponseDto;
use App\DTOs\Cart\CartPromotionInfoDto;
use App\DTOs\Cart\CombinationDetailInfoDto;
use App\DTOs\Cart\UpdateCartItemQuantityDto;

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
        Log::info('[CartRepository::getCartItemsInfo] START', [
            'userPublicId' => $userPublicId,
        ]);

        try {
            $rows = DB::select('CALL SP_GetCartInformations(?, @success, @message)', [$userPublicId]);

            Log::info('[CartRepository::getCartItemsInfo] SP executed', [
                'userPublicId' => $userPublicId,
                'rows_count'   => count($rows),
                'rows_raw'     => $rows,   // Remove in production
            ]);
        } catch (\Exception $e) {
            Log::error('[CartRepository::getCartItemsInfo] SP call FAILED', [
                'userPublicId' => $userPublicId,
                'error'        => $e->getMessage(),
                'trace'        => $e->getTraceAsString(),
            ]);
            throw $e;
        }

        try {
            $result = DB::selectOne('SELECT @success AS success, @message AS message');

            Log::info('[CartRepository::getCartItemsInfo] OUT params fetched', [
                'userPublicId'    => $userPublicId,
                'result_raw'      => $result,        // See exact values returned
                'success_value'   => $result->success,
                'success_type'    => gettype($result->success),  // int / string / bool ?
                'message_value'   => $result->message,
            ]);
        } catch (\Exception $e) {
            Log::error('[CartRepository::getCartItemsInfo] OUT params fetch FAILED', [
                'userPublicId' => $userPublicId,
                'error'        => $e->getMessage(),
            ]);
            throw $e;
        }

        // ⚠️ Common trap: MySQL returns '1'/'0' as string, not true/false
        if (!$result->success) {
            Log::warning('[CartRepository::getCartItemsInfo] SP returned failure', [
                'userPublicId'  => $userPublicId,
                'success'       => $result->success,
                'message'       => $result->message,
            ]);
            throw new BusinessValidationException($result->message, 404);
        }

        try {
            $mapped = array_map(
                fn($row) => CartItemResponseDto::fromInfoDto(CartItemInfoDto::fromRow($row)),
                $rows
            );

            Log::info('[CartRepository::getCartItemsInfo] Mapping SUCCESS', [
                'userPublicId' => $userPublicId,
                'mapped_count' => count($mapped),
            ]);

            return $mapped;
        } catch (\Exception $e) {
            Log::error('[CartRepository::getCartItemsInfo] DTO mapping FAILED', [
                'userPublicId' => $userPublicId,
                'error'        => $e->getMessage(),
                'trace'        => $e->getTraceAsString(),
            ]);
            throw $e;
        }
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
    public function updateItemQuantity(UpdateCartItemQuantityDto $dto): string
    {
        DB::select('CALL SP_UpdateCartItemQuantity(?, ?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->cartItemId,
            $dto->quantity,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'introuvable') ? 404
                : (str_contains($result->message, 'Accès refusé') ? 403 : 422);
            throw new BusinessValidationException($result->message, $status);
        }

        return $result->message;
    }
    public function clearCart(string $userPublicId): void
    {
        Log::info("CLEAR CART", ['userPublicId' => $userPublicId]);

        DB::select('CALL SP_ClearCart(?, @success, @message)', [
            $userPublicId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        Log::info("CLEAR CART RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }
    }
}
