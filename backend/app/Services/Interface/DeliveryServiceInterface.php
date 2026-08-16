<?php
// app/Services/Interface/DeliveryServiceInterface.php

namespace App\Services\Interface;

use App\DTOs\Delivery\AddOrderItemToDeliveryDto;
use App\DTOs\Delivery\ApproveDeliveryProfileDto;
use App\DTOs\Delivery\DeliveryDetailsDto;
use App\DTOs\Delivery\DeliveryProfileBasicDto;
use App\DTOs\Delivery\DeliveryProfileDetailsDto;
use App\DTOs\Delivery\DeliveryResultDto;
use App\DTOs\Delivery\GetAllDeliveryProfilesDto;
use App\DTOs\Delivery\GetDeliveryHistoryDto;
use App\DTOs\Delivery\GetRecommendedDeliveriesDto;
use App\DTOs\Delivery\GetVendorDeliveriesDto;
use App\DTOs\Delivery\PaginatedDeliveryHistoryDto;
use App\DTOs\Delivery\PaginatedDeliveryProfilesDto;
use App\DTOs\Delivery\PaginatedRecommendedDeliveriesDto;
use App\DTOs\Delivery\PaginatedVendorDeliveriesDto;
use App\DTOs\Delivery\SuspendDeliveryProfileDto;
use App\DTOs\Delivery\UpdateDeliveryLocationDto;

interface DeliveryServiceInterface
{
    public function addOrderItemToDelivery(AddOrderItemToDeliveryDto $dto): DeliveryResultDto;

    public function getAllDeliveryProfiles(GetAllDeliveryProfilesDto $dto): PaginatedDeliveryProfilesDto;
    public function getDeliveryProfileById(int $deliveryProfileId): DeliveryProfileDetailsDto;
    public function approveDeliveryProfile(ApproveDeliveryProfileDto $dto): void;
    public function suspendDeliveryProfile(SuspendDeliveryProfileDto $dto): void;
    public function getRecommendedDeliveries(GetRecommendedDeliveriesDto $dto): PaginatedRecommendedDeliveriesDto;
    public function getDeliveryProfileByUserId(int $userId): ?DeliveryProfileBasicDto;
    public function updateDeliveryLocation(UpdateDeliveryLocationDto $dto): void;
    public function getDeliveryHistory(GetDeliveryHistoryDto $dto): PaginatedDeliveryHistoryDto;
    // Interface + implementation

    public function acceptDeliveryById(int $deliveryId, int $deliveryProfileId): void;
    public function getDeliveryDetails(int $deliveryId): DeliveryDetailsDto;
    public function getVendorDeliveries(GetVendorDeliveriesDto $dto): PaginatedVendorDeliveriesDto;
    public function markDeliveryPickedUp(int $deliveryId, int $deliveryProfileId): void;
}
