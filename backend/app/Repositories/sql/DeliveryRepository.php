<?php
// app/Repositories/sql/DeliveryRepository.php

namespace App\Repositories\sql;

use App\DTOs\Auth\DeliveryRegisterDto;
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
  public function registerDelivery(
        DeliveryRegisterDto $dto,
        string $passwordHash,
        string $refreshTokenHash,
        string $ip,
        int $refreshTtlDays
    ): object {
        Log::info("========== REGISTER DELIVERY START ==========", [
            'email' => $dto->email,
            'phoneNumber' => $dto->phoneNumber,
        ]);

        DB::select(
            'CALL SP_RegisterDeliveryAccount(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @success, @message, @userId, @publicId, @deliveryProfileId)',
            [
                $dto->firstName,
                $dto->lastName,
                $dto->email,
                $dto->phoneNumber,
                $passwordHash,
                $dto->vehicleType,
                $dto->licensePlate,
                $dto->assignedBy,
                $refreshTokenHash,
                $ip,
                $refreshTtlDays,
            ]
        );

        $result = DB::selectOne(
            'SELECT @success AS success, @message AS message, @userId AS userId, @publicId AS publicId, @deliveryProfileId AS deliveryProfileId'
        );

        Log::info("REGISTER DELIVERY RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== REGISTER DELIVERY SUCCESS ==========");

        return $result;
    }
}
