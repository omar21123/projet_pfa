<?php
// app/Repositories/Interface/DeliveryRepositoryInterface.php

namespace App\Repositories\Interface;

use App\DTOs\Auth\DeliveryRegisterDto;
use App\DTOs\Delivery\AddOrderItemToDeliveryDto;
use App\DTOs\Delivery\CreateDeliveryFromOrderDto;
use App\DTOs\Delivery\DeliveryResultDto;

interface DeliveryRepositoryInterface
{
    public function addOrderItemToDelivery(AddOrderItemToDeliveryDto $dto): DeliveryResultDto;
    // app/Repositories/Interface/AuthRepositoryInterface.php — add:
   public function registerDelivery(
        DeliveryRegisterDto $dto,
        string $passwordHash,
        string $refreshTokenHash,
        string $ip,
        int $refreshTtlDays
    ): object;
}
