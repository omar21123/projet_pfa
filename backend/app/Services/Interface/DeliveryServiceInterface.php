<?php
// app/Services/Interface/DeliveryServiceInterface.php

namespace App\Services\Interface;

use App\DTOs\Delivery\AddOrderItemToDeliveryDto;
use App\DTOs\Delivery\DeliveryResultDto;

interface DeliveryServiceInterface
{
    public function addOrderItemToDelivery(AddOrderItemToDeliveryDto $dto): DeliveryResultDto;
}