<?php
// app/Repositories/Interface/DeliveryRepositoryInterface.php

namespace App\Repositories\Interface;

use App\DTOs\Auth\DeliveryRegisterDto;
use App\DTOs\Delivery\AddOrderItemToDeliveryDto;
use App\DTOs\Delivery\ApproveDeliveryProfileDto;
use App\DTOs\Delivery\DeliveryProfileDetailsDto;
use App\DTOs\Delivery\DeliveryResultDto;
use App\DTOs\Delivery\GetAllDeliveryProfilesDto;
use App\DTOs\Delivery\PaginatedDeliveryProfilesDto;
use App\DTOs\Delivery\SuspendDeliveryProfileDto;

interface DeliveryRepositoryInterface
{
    public function addOrderItemToDelivery(AddOrderItemToDeliveryDto $dto): DeliveryResultDto;

    public function registerDelivery(
        DeliveryRegisterDto $dto,
        string $passwordHash,
        string $refreshTokenHash,
        string $ip,
        int $refreshTtlDays
    ): object;

    public function getAllDeliveryProfiles(GetAllDeliveryProfilesDto $dto): PaginatedDeliveryProfilesDto;

    public function getDeliveryProfileById(int $deliveryProfileId): DeliveryProfileDetailsDto;

    public function approveDeliveryProfile(ApproveDeliveryProfileDto $dto): int;
    public function suspendDeliveryProfile(SuspendDeliveryProfileDto $dto): void;
}
