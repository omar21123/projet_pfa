<?php
// app/Repositories/sql/OrderRepository.php

namespace App\Repositories\sql;

use App\DTOs\Order\AddOrderItemDto;
use App\DTOs\Order\CreateOrderDto;
use App\DTOs\Order\OrderItemResultDto;
use App\DTOs\Order\OrderResultDto;
use App\Repositories\Interface\OrderRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\DTOs\Order\OrderDto;

class OrderRepository implements OrderRepositoryInterface
{
    public function create(CreateOrderDto $dto): OrderResultDto
    {
        Log::info("========== CREATE ORDER START ==========", (array) $dto);
        DB::select(
            'CALL SP_CreateOrder(?, ?, ?, ?, ?, @orderId, @orderNumber, @success, @message)',
            [
                $dto->userPublicId,
                $dto->addressId,
                $dto->paymentMethodId,
                $dto->subtotal,
                $dto->notes,
            ]
        );
        $result = DB::selectOne(
            'SELECT @orderId AS orderId, @orderNumber AS orderNumber, @success AS success, @message AS message'
        );

        Log::info("CREATE ORDER RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== CREATE ORDER SUCCESS ==========");

        return OrderResultDto::fromOutput($result);
    }
    public function addItem(AddOrderItemDto $dto): OrderItemResultDto
    {
        Log::info("========== ADD ORDER ITEM START ==========", (array) $dto);

        DB::select(
            'CALL SP_CreateOrderItem(?, ?, ?, ?, ?, ?, @orderItemId, @success, @message)',
            [
                $dto->orderId,
                $dto->productId,
                $dto->quantity,
                $dto->combinationId,
                $dto->promotionId,
                $dto->userPublicId,
            ]
        );

        $result = DB::selectOne(
            'SELECT @orderItemId AS orderItemId, @success AS success, @message AS message'
        );

        Log::info("ADD ORDER ITEM RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        return OrderItemResultDto::fromOutput($result);
    }

    public function recalculateTotals(int $orderId): void
    {
        Log::info("RECALCULATE ORDER TOTALS", ['orderId' => $orderId]);

        DB::select('CALL SP_RecalculateOrderTotals(?, @success, @message)', [
            $orderId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        Log::info("RECALCULATE ORDER TOTALS RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }
    }

    public function findById(int $orderId): OrderDto
    {
        $rows = DB::select('CALL SP_GetOrderById(?)', [$orderId]);

        if (empty($rows)) {
            throw new BusinessValidationException('Commande introuvable.', 404);
        }

        return OrderDto::fromRow($rows[0]);
    }
}
