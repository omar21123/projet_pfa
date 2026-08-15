<?php
// app/Repositories/Interface/DeliveryRepositoryInterface.php

namespace App\Repositories\Interface;

use App\DTOs\Delivery\AddOrderItemToDeliveryDto;
use App\DTOs\Delivery\CreateDeliveryFromOrderDto;
use App\DTOs\Delivery\DeliveryResultDto;

interface DeliveryRepositoryInterface
{
    public function addOrderItemToDelivery(AddOrderItemToDeliveryDto $dto): DeliveryResultDto;

}