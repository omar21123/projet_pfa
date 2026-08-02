<?php

namespace App\Repositories\sql;

use App\DTOs\Cart\AddCartItemDto;
use App\Repositories\Interface\CartRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;
use App\DTOs\Cart\RemoveCartItemDto;


class CartRepository implements CartRepositoryInterface
{
    public function addItem(AddCartItemDto $dto): string
    {
        DB::select('CALL SP_AddCartItem(?, ?, ?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->productId,
            $dto->compositionId,
            $dto->unitPrice,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'introuvable') ? 404 : 422;
            throw new BusinessValidationException($result->message, $status);
        }

        return $result->message;
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
}
