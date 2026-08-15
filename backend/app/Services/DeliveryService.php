<?php
// app/Services/DeliveryService.php

namespace App\Services;

use App\DTOs\Delivery\AddOrderItemToDeliveryDto;
use App\DTOs\Delivery\DeliveryResultDto;
use App\Repositories\Interface\DeliveryRepositoryInterface;
use App\Services\Interface\DeliveryServiceInterface;

class DeliveryService implements DeliveryServiceInterface
{
    public function __construct(
        protected DeliveryRepositoryInterface $deliveryRepository
    ) {
    }

    public function addOrderItemToDelivery(AddOrderItemToDeliveryDto $dto): DeliveryResultDto
    {
        return $this->deliveryRepository->addOrderItemToDelivery($dto);
    }
}