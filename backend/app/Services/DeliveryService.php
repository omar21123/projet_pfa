<?php
// app/Services/DeliveryService.php

namespace App\Services;

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
use App\DTOs\Delivery\MarkDeliveryDeliveredResultDto;
use App\DTOs\Delivery\MarkOrderAsShippedResultDto;
use App\DTOs\Delivery\PaginatedDeliveryHistoryDto;
use App\DTOs\Delivery\PaginatedDeliveryProfilesDto;
use App\DTOs\Delivery\PaginatedRecommendedDeliveriesDto;
use App\DTOs\Delivery\PaginatedVendorDeliveriesDto;
use App\DTOs\Delivery\SuspendDeliveryProfileDto;
use App\DTOs\Delivery\UpdateDeliveryLocationDto;
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

    public function approveDeliveryProfile(ApproveDeliveryProfileDto $dto): void
    {
        $this->deliveryRepository->approveDeliveryProfile($dto);
    }

    public function suspendDeliveryProfile(SuspendDeliveryProfileDto $dto): void
    {
        $this->deliveryRepository->suspendDeliveryProfile($dto);
    }
    // Interface + implementation — same pass-through pattern as before

    public function getRecommendedDeliveries(GetRecommendedDeliveriesDto $dto): PaginatedRecommendedDeliveriesDto
    {
        return $this->deliveryRepository->getRecommendedDeliveries($dto);
    }
    public function getDeliveryProfileByUserId(int $userId): ?DeliveryProfileBasicDto
    {
        return $this->deliveryRepository->getDeliveryProfileByUserId($userId);
    }
    public function updateDeliveryLocation(UpdateDeliveryLocationDto $dto): void
    {
        $this->deliveryRepository->updateDeliveryLocation($dto);
    }
    // Interface + implementation — pass-through

    public function getDeliveryHistory(GetDeliveryHistoryDto $dto): PaginatedDeliveryHistoryDto
    {
        return $this->deliveryRepository->getDeliveryHistory($dto);
    }
    // Interface + implementation

    public function acceptDeliveryById(int $deliveryId, int $deliveryProfileId): void
    {
        $this->deliveryRepository->acceptDeliveryById($deliveryId, $deliveryProfileId);
    }
    // Interface + implementation — pass-through

    public function getVendorDeliveries(GetVendorDeliveriesDto $dto): PaginatedVendorDeliveriesDto
    {
        return $this->deliveryRepository->getVendorDeliveries($dto);
    }

    public function getDeliveryDetails(int $deliveryId): DeliveryDetailsDto
    {
        return $this->deliveryRepository->getDeliveryDetails($deliveryId);
    }
    // Interface + implementation

    public function markDeliveryPickedUp(int $deliveryId, int $deliveryProfileId): void
    {
        $this->deliveryRepository->markDeliveryPickedUp($deliveryId, $deliveryProfileId);
    }
    public function markOrderAsShipped(int $orderId, int $vendorProfileId): MarkOrderAsShippedResultDto
    {
        return $this->deliveryRepository->markOrderAsShipped($orderId, $vendorProfileId);
    }
    public function markDeliveryInTransit(int $deliveryId, int $deliveryProfileId): void
    {
        $this->deliveryRepository->markDeliveryInTransit($deliveryId, $deliveryProfileId);
    }
    // DeliveryService — add this method

    public function markDeliveryDeliveredByLivreur(
        int $deliveryId,
        int $deliveryProfileId,
        ?float $collectedAmount
    ): MarkDeliveryDeliveredResultDto {
        return $this->deliveryRepository->markDeliveryDeliveredByLivreur($deliveryId, $deliveryProfileId, $collectedAmount);
    }
}
