<?php
// app/Repositories/sql/DeliveryRepository.php

namespace App\Repositories\sql;

use App\DTOs\Delivery\AddOrderItemToDeliveryDto;
use App\DTOs\Delivery\DeliveryResultDto;
use App\Exceptions\BusinessValidationException;
use App\Repositories\Interface\DeliveryRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DeliveryRepository implements DeliveryRepositoryInterface
{
    public function addOrderItemToDelivery(AddOrderItemToDeliveryDto $dto): DeliveryResultDto
    {
        Log::info("========== ADD ORDER ITEM TO DELIVERY START ==========", (array) $dto);

        DB::select(
            'CALL SP_AddOrderItemToDelivery(?, ?, ?, ?, ?, @success, @message, @deliveryId)',
            [
                $dto->productId,
                $dto->orderId,
                $dto->orderItemId,
                $dto->addressToId,
                $dto->notes,
            ]
        );

        $result = DB::selectOne(
            'SELECT @deliveryId AS deliveryId, @success AS success, @message AS message'
        );

        Log::info("ADD ORDER ITEM TO DELIVERY RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== ADD ORDER ITEM TO DELIVERY SUCCESS ==========");

        return DeliveryResultDto::fromOutput($result);
    }
}