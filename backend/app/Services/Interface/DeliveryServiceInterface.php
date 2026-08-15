<?php
// app/Services/Interface/DeliveryServiceInterface.php

namespace App\Services\Interface;

use App\DTOs\Delivery\AddOrderItemToDeliveryDto;
use App\DTOs\Delivery\DeliveryProfileDetailsDto;
use App\DTOs\Delivery\DeliveryResultDto;
use App\DTOs\Delivery\GetAllDeliveryProfilesDto;
use App\DTOs\Delivery\PaginatedDeliveryProfilesDto;

interface DeliveryServiceInterface
{
    public function addOrderItemToDelivery(AddOrderItemToDeliveryDto $dto): DeliveryResultDto;

    public function getAllDeliveryProfiles(GetAllDeliveryProfilesDto $dto): PaginatedDeliveryProfilesDto;
    // Interface — add to DeliveryServiceInterface

public function getDeliveryProfileById(int $deliveryProfileId): DeliveryProfileDetailsDto;
}