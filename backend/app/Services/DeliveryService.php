<?php
// app/Services/DeliveryService.php

namespace App\Services;

use App\DTOs\Delivery\AddOrderItemToDeliveryDto;
use App\DTOs\Delivery\DeliveryProfileDetailsDto;
use App\DTOs\Delivery\DeliveryResultDto;
use App\DTOs\Delivery\GetAllDeliveryProfilesDto;
use App\DTOs\Delivery\PaginatedDeliveryProfilesDto;
use App\Repositories\Interface\DeliveryRepositoryInterface;
use App\Services\Interface\DeliveryServiceInterface;

class DeliveryService implements DeliveryServiceInterface
{
    public function __construct(
        protected DeliveryRepositoryInterface $deliveryRepository
    ) {}

    public function addOrderItemToDelivery(AddOrderItemToDeliveryDto $dto): DeliveryResultDto
    {
        return $this->deliveryRepository->addOrderItemToDelivery($dto);
    }

    public function getAllDeliveryProfiles(GetAllDeliveryProfilesDto $dto): PaginatedDeliveryProfilesDto
    {
        return $this->deliveryRepository->getAllDeliveryProfiles($dto);
    }

    public function getDeliveryProfileById(int $deliveryProfileId): DeliveryProfileDetailsDto
    {
        return $this->deliveryRepository->getDeliveryProfileById($deliveryProfileId);
    }
}
