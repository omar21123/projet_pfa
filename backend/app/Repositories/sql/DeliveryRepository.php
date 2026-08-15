<?php
// app/Repositories/sql/DeliveryRepository.php

namespace App\Repositories\sql;

use App\DTOs\Auth\DeliveryRegisterDto;
use App\DTOs\Delivery\AddOrderItemToDeliveryDto;
use App\DTOs\Delivery\ApproveDeliveryProfileDto;
use App\DTOs\Delivery\DeliveryProfileBasicDto;
use App\DTOs\Delivery\DeliveryProfileDetailsDto;
use App\DTOs\Delivery\DeliveryProfileListItemDto;
use App\DTOs\Delivery\DeliveryResultDto;
use App\DTOs\Delivery\GetAllDeliveryProfilesDto;
use App\DTOs\Delivery\GetRecommendedDeliveriesDto;
use App\DTOs\Delivery\PaginatedDeliveryProfilesDto;
use App\DTOs\Delivery\PaginatedRecommendedDeliveriesDto;
use App\DTOs\Delivery\RecommendedDeliveryItemDto;
use App\DTOs\Delivery\SuspendDeliveryProfileDto;
use App\DTOs\Delivery\UpdateDeliveryLocationDto;
use App\Exceptions\BusinessValidationException;
use App\Repositories\Interface\DeliveryRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use PDO;

class DeliveryRepository implements DeliveryRepositoryInterface
{
    public function addOrderItemToDelivery(AddOrderItemToDeliveryDto $dto): DeliveryResultDto
    {
        Log::info("========== ADD ORDER ITEM TO DELIVERY START ==========", (array) $dto);

        DB::select(
            'CALL SP_AddOrderItemToDelivery(?, ?, ?, ?, ?, @success, @message, @deliveryId)',
            [
                $dto->productId,
                $dto->orderId,
                $dto->orderItemId,
                $dto->addressToId,
                $dto->notes,
            ]
        );

        $result = DB::selectOne(
            'SELECT @deliveryId AS deliveryId, @success AS success, @message AS message'
        );

        Log::info("ADD ORDER ITEM TO DELIVERY RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== ADD ORDER ITEM TO DELIVERY SUCCESS ==========");

        return DeliveryResultDto::fromOutput($result);
    }

    public function registerDelivery(
        DeliveryRegisterDto $dto,
        string $passwordHash,
        string $refreshTokenHash,
        string $ip,
        int $refreshTtlDays
    ): object {
        Log::info("========== REGISTER DELIVERY START ==========", [
            'email' => $dto->email,
            'phoneNumber' => $dto->phoneNumber,
        ]);

        DB::select(
            'CALL SP_RegisterDeliveryAccount(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @success, @message, @userId, @publicId, @deliveryProfileId)',
            [
                $dto->firstName,
                $dto->lastName,
                $dto->email,
                $dto->phoneNumber,
                $passwordHash,
                $dto->vehicleType,
                $dto->licensePlate,
                $dto->assignedBy,
                $refreshTokenHash,
                $ip,
                $refreshTtlDays,
            ]
        );

        $result = DB::selectOne(
            'SELECT @success AS success, @message AS message, @userId AS userId, @publicId AS publicId, @deliveryProfileId AS deliveryProfileId'
        );

        Log::info("REGISTER DELIVERY RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== REGISTER DELIVERY SUCCESS ==========");

        return $result;
    }

    public function getAllDeliveryProfiles(GetAllDeliveryProfilesDto $dto): PaginatedDeliveryProfilesDto
    {
        Log::info("========== GET ALL DELIVERY PROFILES START ==========", (array) $dto);

        // SP returns two result sets (COUNT then paged rows) + OUT params.
        // DB::select() only surfaces the first result set, so we go through
        // the raw PDO statement to walk both rowsets via nextRowset().
        $pdo = DB::connection()->getPdo();

        $stmt = $pdo->prepare(
            'CALL SP_GetAllDeliveryProfiles(?, ?, ?, ?, ?, ?, @success, @message, @total)'
        );

        $stmt->execute([
            $dto->search,
            $dto->isAvailable === null ? null : (int) $dto->isAvailable,
            $dto->isApproved  === null ? null : (int) $dto->isApproved,
            $dto->isSuspended === null ? null : (int) $dto->isSuspended,
            $dto->page,
            $dto->perPage,
        ]);

        // First rowset: not used directly here (COUNT is captured via @total),
        // but must be consumed before moving to the next rowset.
        $stmt->closeCursor();

        $rows = [];
        // The paged SELECT is the second/last real result set before OUT params.
        // We re-run a plain query for the rows for driver-safety (some MySQL
        // drivers don't expose nextRowset reliably across CALL boundaries).
        $rows = DB::select(
            'SELECT
                dp.DeliveryProfileID, u.AvatarURL, u.DisplayName, u.Email,
                dp.VehicleType, dp.LicensePlate, dp.Rating, dp.DeliveryCount,
                dp.IdentityVerified, u.LastLoginAt, dp.IsAvailable, dp.IsApproved
            FROM DeliveryProfiles dp
            INNER JOIN Users u ON u.UserID = dp.UserID
            WHERE (? IS NULL OR ? = \'\' OR u.DisplayName LIKE CONCAT(\'%\', ?, \'%\')
                   OR u.Email LIKE CONCAT(\'%\', ?, \'%\') OR dp.LicensePlate LIKE CONCAT(\'%\', ?, \'%\'))
              AND (? IS NULL OR dp.IsAvailable = ?)
              AND (? IS NULL OR dp.IsApproved  = ?)
              AND (? IS NULL OR dp.IsSuspended = ?)
            ORDER BY dp.CreatedAt DESC
            LIMIT ? OFFSET ?',
            [
                $dto->search,
                $dto->search,
                $dto->search,
                $dto->search,
                $dto->search,
                $dto->isAvailable === null ? null : (int) $dto->isAvailable,
                $dto->isAvailable === null ? null : (int) $dto->isAvailable,
                $dto->isApproved  === null ? null : (int) $dto->isApproved,
                $dto->isApproved  === null ? null : (int) $dto->isApproved,
                $dto->isSuspended === null ? null : (int) $dto->isSuspended,
                $dto->isSuspended === null ? null : (int) $dto->isSuspended,
                $dto->perPage,
                ($dto->page - 1) * $dto->perPage,
            ]
        );

        $result = DB::selectOne('SELECT @success AS success, @message AS message, @total AS total');

        Log::info("GET ALL DELIVERY PROFILES RESULT", ['total' => $result->total ?? null, 'count' => count($rows)]);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== GET ALL DELIVERY PROFILES SUCCESS ==========");

        return new PaginatedDeliveryProfilesDto(
            data: array_map(fn($row) => DeliveryProfileListItemDto::fromRow($row), $rows),
            total: (int) $result->total,
            page: $dto->page,
            perPage: $dto->perPage,
        );
    }
    public function getDeliveryProfileById(int $deliveryProfileId): DeliveryProfileDetailsDto
    {
        Log::info("========== GET DELIVERY PROFILE BY ID START ==========", [
            'deliveryProfileId' => $deliveryProfileId,
        ]);

        $rows = DB::select(
            'CALL SP_GetDeliveryProfileById(?, @success, @message)',
            [$deliveryProfileId]
        );

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        Log::info("GET DELIVERY PROFILE BY ID RESULT", ['success' => $result->success ?? null, 'rows' => count($rows)]);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 404);
        }

        if (empty($rows)) {
            throw new BusinessValidationException('Profil livreur introuvable.', 404);
        }

        Log::info("========== GET DELIVERY PROFILE BY ID SUCCESS ==========");

        return DeliveryProfileDetailsDto::fromRow($rows[0]);
    }
    public function approveDeliveryProfile(ApproveDeliveryProfileDto $dto): int
    {
        Log::info("========== APPROVE DELIVERY PROFILE START ==========", (array) $dto);

        DB::select(
            'CALL SP_ApproveDeliveryProfile(?, ?, @success, @message, @deliveryWalletId)',
            [
                $dto->deliveryProfileId,
                $dto->approvedBy,
            ]
        );

        $result = DB::selectOne(
            'SELECT @success AS success, @message AS message, @deliveryWalletId AS deliveryWalletId'
        );

        Log::info("APPROVE DELIVERY PROFILE RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== APPROVE DELIVERY PROFILE SUCCESS ==========");

        return (int) $result->deliveryWalletId;
    }
    public function suspendDeliveryProfile(SuspendDeliveryProfileDto $dto): void
    {
        Log::info("========== SUSPEND DELIVERY PROFILE START ==========", (array) $dto);

        DB::select(
            'CALL SP_SuspendDeliveryProfile(?, ?, ?, @success, @message)',
            [
                $dto->deliveryProfileId,
                $dto->suspendedBy,
                $dto->reason,
            ]
        );

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        Log::info("SUSPEND DELIVERY PROFILE RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== SUSPEND DELIVERY PROFILE SUCCESS ==========");
    }
    public function getRecommendedDeliveries(GetRecommendedDeliveriesDto $dto): PaginatedRecommendedDeliveriesDto
    {
        Log::info("========== GET RECOMMENDED DELIVERIES START ==========", (array) $dto);

        $pdo = DB::connection()->getPdo();

        $stmt = $pdo->prepare(
            'CALL SP_GetRecommendedDeliveries(?, ?, ?, ?, @success, @message, @total)'
        );

        $stmt->execute([
            $dto->deliveryProfileId,
            $dto->maxDistanceKm,
            $dto->page,
            $dto->perPage,
        ]);

        $rows = $stmt->fetchAll(PDO::FETCH_OBJ);
        $stmt->closeCursor();

        $result = DB::selectOne('SELECT @success AS success, @message AS message, @total AS total');

        Log::info("GET RECOMMENDED DELIVERIES RESULT", [
            'success' => $result->success ?? null,
            'message' => $result->message ?? null,
            'total' => $result->total ?? null,
            'rows' => count($rows),
        ]);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        return new PaginatedRecommendedDeliveriesDto(
            data: array_map(fn($row) => RecommendedDeliveryItemDto::fromRow($row), $rows),
            total: (int) ($result->total ?? 0),
            page: $dto->page,
            perPage: $dto->perPage,
        );
    }
    public function getDeliveryProfileByUserId(int $userId): ?DeliveryProfileBasicDto
    {
        Log::info("========== GET DELIVERY PROFILE BY USER ID START ==========", ['userId' => $userId]);

        $row = DB::selectOne(
            'SELECT DeliveryProfileID, UserID, IsApproved, IsSuspended
         FROM DeliveryProfiles
         WHERE UserID = ?
         LIMIT 1',
            [$userId]
        );

        Log::info("GET DELIVERY PROFILE BY USER ID RESULT", ['found' => $row !== null]);

        if (!$row) {
            return null;
        }

        return DeliveryProfileBasicDto::fromRow($row);
    }
    // DeliveryRepository — add this method

    public function updateDeliveryLocation(UpdateDeliveryLocationDto $dto): void
    {
        Log::info("========== UPDATE DELIVERY LOCATION START ==========", (array) $dto);

        DB::select(
            'CALL SP_UpdateDeliveryLocation(?, ?, ?, @success, @message)',
            [
                $dto->deliveryProfileId,
                $dto->latitude,
                $dto->longitude,
            ]
        );

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        Log::info("UPDATE DELIVERY LOCATION RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== UPDATE DELIVERY LOCATION SUCCESS ==========");
    }
}
