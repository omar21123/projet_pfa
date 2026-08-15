<?php
// app/Services/Interface/DeliveryServiceInterface.php

namespace App\Services\Interface;

use App\DTOs\Delivery\AddOrderItemToDeliveryDto;
use App\DTOs\Delivery\ApproveDeliveryProfileDto;
use App\DTOs\Delivery\DeliveryProfileDetailsDto;
use App\DTOs\Delivery\DeliveryResultDto;
use App\DTOs\Delivery\GetAllDeliveryProfilesDto;
use App\DTOs\Delivery\PaginatedDeliveryProfilesDto;
use App\DTOs\Delivery\SuspendDeliveryProfileDto;

interface DeliveryServiceInterface
{
    public function addOrderItemToDelivery(AddOrderItemToDeliveryDto $dto): DeliveryResultDto;

    public function getAllDeliveryProfiles(GetAllDeliveryProfilesDto $dto): PaginatedDeliveryProfilesDto;
    public function getDeliveryProfileById(int $deliveryProfileId): DeliveryProfileDetailsDto;
    public function approveDeliveryProfile(ApproveDeliveryProfileDto $dto): void;
    public function suspendDeliveryProfile(SuspendDeliveryProfileDto $dto): void;
}
