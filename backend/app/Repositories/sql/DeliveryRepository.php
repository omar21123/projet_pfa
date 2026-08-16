<?php
// app/Repositories/sql/DeliveryRepository.php

namespace App\Repositories\sql;

use App\DTOs\Auth\DeliveryRegisterDto;
use App\DTOs\Delivery\AddOrderItemToDeliveryDto;
use App\DTOs\Delivery\ApproveDeliveryProfileDto;
use App\DTOs\Delivery\CancelDeliveryDto;
use App\DTOs\Delivery\DeliveryDetailsDto;
use App\DTOs\Delivery\DeliveryHistoryItemDto;
use App\DTOs\Delivery\DeliveryProfileBasicDto;
use App\DTOs\Delivery\DeliveryProfileDetailsDto;
use App\DTOs\Delivery\DeliveryProfileListItemDto;
use App\DTOs\Delivery\DeliveryResultDto;
use App\DTOs\Delivery\DeliveryWalletDto;
use App\DTOs\Delivery\GetAllDeliveryProfilesDto;
use App\DTOs\Delivery\GetDeliveryHistoryDto;
use App\DTOs\Delivery\GetRecommendedDeliveriesDto;
use App\DTOs\Delivery\GetVendorDeliveriesDto;
use App\DTOs\Delivery\MarkDeliveryDeliveredResultDto;
use App\DTOs\Delivery\MarkOrderAsShippedResultDto;
use App\DTOs\Delivery\OutstandingCashItemDto;
use App\DTOs\Delivery\PaginatedDeliveryHistoryDto;
use App\DTOs\Delivery\PaginatedDeliveryProfilesDto;
use App\DTOs\Delivery\PaginatedOutstandingCashDto;
use App\DTOs\Delivery\PaginatedRecommendedDeliveriesDto;
use App\DTOs\Delivery\PaginatedVendorDeliveriesDto;
use App\DTOs\Delivery\PaginatedWithdrawHistoryDto;
use App\DTOs\Delivery\PendingCashItemDto;
use App\DTOs\Delivery\PendingCashSummaryDto;
use App\DTOs\Delivery\RecommendedDeliveryItemDto;
use App\DTOs\Delivery\RemitCashDto;
use App\DTOs\Delivery\RemitCashResultDto;
use App\DTOs\Delivery\RequestWithdrawDto;
use App\DTOs\Delivery\SuspendDeliveryProfileDto;
use App\DTOs\Delivery\UpdateDeliveryLocationDto;
use App\DTOs\Delivery\VendorDeliveryListItemDto;
use App\DTOs\Delivery\WithdrawHistoryItemDto;
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

    public function getDeliveryHistory(GetDeliveryHistoryDto $dto): PaginatedDeliveryHistoryDto
    {
        Log::info("========== GET DELIVERY HISTORY START ==========", (array) $dto);

        $rows = DB::select(
            'CALL SP_GetDeliveryHistoryByProfile(?, ?, ?, ?, ?, ?, @success, @message, @total)',
            [
                $dto->deliveryProfileId,
                $dto->statusCode,
                $dto->dateFrom,
                $dto->dateTo,
                $dto->page,
                $dto->perPage,
            ]
        );

        $result = DB::selectOne(
            'SELECT @success AS success, @message AS message, @total AS total'
        );

        Log::info("GET DELIVERY HISTORY RESULT", [
            'success' => $result->success ?? null,
            'rows'    => count($rows),
        ]);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 404);
        }

        return new PaginatedDeliveryHistoryDto(
            data: array_map(fn($row) => DeliveryHistoryItemDto::fromRow($row), $rows),
            total: (int) $result->total,
            page: $dto->page,
            perPage: $dto->perPage,
        );
    }
    // DeliveryRepository — add this method

    public function acceptDeliveryById(int $deliveryId, int $deliveryProfileId): void
    {
        Log::info("========== ACCEPT DELIVERY BY ID START ==========", [
            'deliveryId' => $deliveryId,
            'deliveryProfileId' => $deliveryProfileId,
        ]);

        DB::select(
            'CALL SP_AcceptDeliveryByID(?, ?, @success, @message)',
            [$deliveryId, $deliveryProfileId]
        );

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        Log::info("ACCEPT DELIVERY BY ID RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== ACCEPT DELIVERY BY ID SUCCESS ==========");
    }
    // DeliveryRepository — add these methods

    public function getVendorDeliveries(GetVendorDeliveriesDto $dto): PaginatedVendorDeliveriesDto
    {
        Log::info("========== GET VENDOR DELIVERIES START ==========", (array) $dto);

        $vendorExists = DB::selectOne(
            'SELECT COUNT(*) AS cnt FROM VendorProfiles WHERE VendorProfileID = ?',
            [$dto->vendorProfileId]
        )->cnt;

        if (!$vendorExists) {
            throw new BusinessValidationException('Profil vendeur introuvable.', 404);
        }

        $whereStatus = $dto->statusCode !== null ? 'AND ds.Code = ?' : '';
        $whereTaken  = $dto->isTaken !== null
            ? ($dto->isTaken ? 'AND d.DeliveryProfileID IS NOT NULL' : 'AND d.DeliveryProfileID IS NULL')
            : '';

        $filterParams = [$dto->vendorProfileId];
        if ($dto->statusCode !== null) {
            $filterParams[] = $dto->statusCode;
        }

        $total = DB::selectOne(
            "SELECT COUNT(*) AS total
         FROM Deliveries d
         INNER JOIN DeliveryStatuses ds ON ds.DeliveryStatusID = d.DeliveryStatusID
         WHERE d.VendorProfileID = ?
           {$whereStatus} {$whereTaken}",
            $filterParams
        )->total;

        $offset = ($dto->page - 1) * $dto->perPage;
        $rowParams = array_merge($filterParams, [$dto->perPage, $offset]);

        $rows = DB::select(
            "SELECT
            d.DeliveryID,
            d.OrderID,
            ds.Code AS StatusCode,
            ds.Name AS StatusName,
            (d.DeliveryProfileID IS NOT NULL) AS IsTaken,
            d.DeliveryProfileID,
            u.DisplayName AS LivreurName,
            u.PhoneNumber AS LivreurPhone,
            d.DeliveryFee,
            (SELECT COUNT(*) FROM DeliveryItems di WHERE di.DeliveryID = d.DeliveryID) AS TotalItems,
            at.City AS ToCity,
            at.Region AS ToRegion,
            d.RequestedAt,
            d.AcceptedAt,
            d.DeliveredAt
        FROM Deliveries d
        INNER JOIN DeliveryStatuses ds ON ds.DeliveryStatusID = d.DeliveryStatusID
        INNER JOIN Addresses at        ON at.AddressID = d.AddressToID
        LEFT JOIN DeliveryProfiles dp  ON dp.DeliveryProfileID = d.DeliveryProfileID
        LEFT JOIN Users u              ON u.UserID = dp.UserID
        WHERE d.VendorProfileID = ?
          {$whereStatus} {$whereTaken}
        ORDER BY d.RequestedAt DESC
        LIMIT ? OFFSET ?",
            $rowParams
        );

        Log::info("GET VENDOR DELIVERIES RESULT", ['total' => $total, 'count' => count($rows)]);

        return new PaginatedVendorDeliveriesDto(
            data: array_map(fn($row) => VendorDeliveryListItemDto::fromRow($row), $rows),
            total: (int) $total,
            page: $dto->page,
            perPage: $dto->perPage,
        );
    }

    public function getDeliveryDetails(int $deliveryId): DeliveryDetailsDto
    {
        Log::info("========== GET DELIVERY DETAILS START ==========", ['deliveryId' => $deliveryId]);

        $rows = DB::select(
            'CALL SP_GetDeliveryDetails(?, @success, @message)',
            [$deliveryId]
        );

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        Log::info("GET DELIVERY DETAILS RESULT", ['success' => $result->success ?? null, 'rows' => count($rows)]);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 404);
        }

        if (empty($rows)) {
            throw new BusinessValidationException('Livraison introuvable.', 404);
        }

        return DeliveryDetailsDto::fromRow($rows[0]);
    }
    // DeliveryRepository — add this method

    public function markDeliveryPickedUp(int $deliveryId, int $deliveryProfileId): void
    {
        Log::info("========== MARK DELIVERY PICKED UP START ==========", [
            'deliveryId' => $deliveryId,
            'deliveryProfileId' => $deliveryProfileId,
        ]);

        DB::select(
            'CALL SP_MarkDeliveryPickedUp(?, ?, @success, @message)',
            [$deliveryId, $deliveryProfileId]
        );

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        Log::info("MARK DELIVERY PICKED UP RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== MARK DELIVERY PICKED UP SUCCESS ==========");
    }
    public function markOrderAsShipped(int $orderId, int $vendorProfileId): MarkOrderAsShippedResultDto
    {
        Log::info("========== MARK ORDER AS SHIPPED START ==========", [
            'orderId' => $orderId,
            'vendorProfileId' => $vendorProfileId,
        ]);

        DB::select(
            'CALL SP_MarkOrderAsShipped(?, ?, @success, @message, @orderFullyShipped)',
            [$orderId, $vendorProfileId]
        );

        $result = DB::selectOne(
            'SELECT @success AS success, @message AS message, @orderFullyShipped AS orderFullyShipped'
        );

        Log::info("MARK ORDER AS SHIPPED RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== MARK ORDER AS SHIPPED SUCCESS ==========");

        return new MarkOrderAsShippedResultDto(
            orderFullyShipped: (bool) $result->orderFullyShipped,
            message: $result->message,
        );
    }
    public function markDeliveryInTransit(int $deliveryId, int $deliveryProfileId): void
    {
        Log::info("========== MARK DELIVERY IN TRANSIT START ==========", [
            'deliveryId' => $deliveryId,
            'deliveryProfileId' => $deliveryProfileId,
        ]);

        DB::select(
            'CALL SP_MarkDeliveryInTransit(?, ?, @success, @message)',
            [$deliveryId, $deliveryProfileId]
        );

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        Log::info("MARK DELIVERY IN TRANSIT RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== MARK DELIVERY IN TRANSIT SUCCESS ==========");
    }
    // DeliveryRepository — add this method

    public function markDeliveryDeliveredByLivreur(
        int $deliveryId,
        int $deliveryProfileId,
        ?float $collectedAmount
    ): MarkDeliveryDeliveredResultDto {
        Log::info("========== MARK DELIVERY DELIVERED BY LIVREUR START ==========", [
            'deliveryId' => $deliveryId,
            'deliveryProfileId' => $deliveryProfileId,
            'collectedAmount' => $collectedAmount,
        ]);

        DB::select(
            'CALL SP_MarkDeliveryDeliveredByLivreur(?, ?, ?, @success, @message)',
            [$deliveryId, $deliveryProfileId, $collectedAmount]
        );

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        Log::info("MARK DELIVERY DELIVERED BY LIVREUR RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== MARK DELIVERY DELIVERED BY LIVREUR SUCCESS ==========");

        return new MarkDeliveryDeliveredResultDto(message: $result->message);
    }
    public function cancelDelivery(CancelDeliveryDto $dto): void
    {
        Log::info("========== CANCEL DELIVERY START ==========", (array) $dto);

        DB::select(
            'CALL SP_CancelDelivery(?, ?, ?, @success, @message)',
            [$dto->deliveryId, $dto->adminUserId, $dto->reason]
        );

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        Log::info("CANCEL DELIVERY RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== CANCEL DELIVERY SUCCESS ==========");
    }

    public function getOutstandingCashByLivreur(int $page, int $perPage): PaginatedOutstandingCashDto
    {
        Log::info("========== GET OUTSTANDING CASH START ==========", ['page' => $page, 'perPage' => $perPage]);

        $offset = ($page - 1) * $perPage;

        $totalRow = DB::selectOne(
            'SELECT COUNT(DISTINCT DeliveryProfileID) AS total
         FROM DeliveryCashCollections
         WHERE IsCollected = 1 AND IsRemitted = 0'
        );

        $rows = DB::select(
            'SELECT
            dcc.DeliveryProfileID,
            u.DisplayName,
            u.Email,
            u.PhoneNumber,
            SUM(dcc.CollectedAmount)  AS OutstandingAmount,
            COUNT(*)                  AS PendingDeliveriesCount,
            MIN(dcc.CollectedAt)       AS OldestCollectedAt
        FROM DeliveryCashCollections dcc
        INNER JOIN DeliveryProfiles dp ON dp.DeliveryProfileID = dcc.DeliveryProfileID
        INNER JOIN Users u             ON u.UserID = dp.UserID
        WHERE dcc.IsCollected = 1 AND dcc.IsRemitted = 0
        GROUP BY dcc.DeliveryProfileID, u.DisplayName, u.Email, u.PhoneNumber
        ORDER BY OutstandingAmount DESC
        LIMIT ? OFFSET ?',
            [$perPage, $offset]
        );

        Log::info("GET OUTSTANDING CASH RESULT", ['total' => $totalRow->total, 'count' => count($rows)]);

        return new PaginatedOutstandingCashDto(
            data: array_map(fn($row) => OutstandingCashItemDto::fromRow($row), $rows),
            total: (int) $totalRow->total,
            page: $page,
            perPage: $perPage,
        );
    }

    public function remitLivreurCash(RemitCashDto $dto): RemitCashResultDto
    {
        Log::info("========== REMIT LIVREUR CASH START ==========", (array) $dto);

        DB::select(
            'CALL SP_RemitLivreurCash(?, ?, ?, @success, @message, @totalRemitted)',
            [$dto->deliveryProfileId, $dto->adminUserId, $dto->expectedAmount]
        );

        $result = DB::selectOne(
            'SELECT @success AS success, @message AS message, @totalRemitted AS totalRemitted'
        );

        Log::info("REMIT LIVREUR CASH RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== REMIT LIVREUR CASH SUCCESS ==========");

        return new RemitCashResultDto(
            message: $result->message,
            totalRemitted: (float) $result->totalRemitted,
        );
    }

    public function getWalletByProfileId(int $deliveryProfileId): ?DeliveryWalletDto
    {
        Log::info("========== GET DELIVERY WALLET START ==========", ['deliveryProfileId' => $deliveryProfileId]);

        $row = DB::selectOne(
            'SELECT DeliveryWalletID, DeliveryProfileID, CurrentBalance, WithdrawableBalance,
                PendingBalance, CurrencyCode, IsLocked
         FROM DeliveryWallets
         WHERE DeliveryProfileID = ?',
            [$deliveryProfileId]
        );

        Log::info("GET DELIVERY WALLET RESULT", ['found' => (bool) $row]);

        return $row ? DeliveryWalletDto::fromRow($row) : null;
    }

    public function getWithdrawHistory(int $deliveryProfileId, int $page, int $perPage): PaginatedWithdrawHistoryDto
    {
        Log::info("========== GET WITHDRAW HISTORY START ==========", [
            'deliveryProfileId' => $deliveryProfileId,
            'page' => $page,
            'perPage' => $perPage,
        ]);

        $offset = ($page - 1) * $perPage;

        $totalRow = DB::selectOne(
            'SELECT COUNT(*) AS total
         FROM DeliveryWithdrawHistory dwh
         INNER JOIN DeliveryWallets dw ON dw.DeliveryWalletID = dwh.DeliveryWalletID
         WHERE dw.DeliveryProfileID = ?',
            [$deliveryProfileId]
        );

        $rows = DB::select(
            'SELECT dwh.DeliveryWithdrawID, dwh.Amount, dwh.PaymentMethodID,
                dwh.ExternalReference, dwh.Status, dwh.RequestedAt, dwh.ProcessedAt
         FROM DeliveryWithdrawHistory dwh
         INNER JOIN DeliveryWallets dw ON dw.DeliveryWalletID = dwh.DeliveryWalletID
         WHERE dw.DeliveryProfileID = ?
         ORDER BY dwh.RequestedAt DESC
         LIMIT ? OFFSET ?',
            [$deliveryProfileId, $perPage, $offset]
        );

        Log::info("GET WITHDRAW HISTORY RESULT", ['total' => $totalRow->total, 'count' => count($rows)]);

        return new PaginatedWithdrawHistoryDto(
            data: array_map(fn($row) => WithdrawHistoryItemDto::fromRow($row), $rows),
            total: (int) $totalRow->total,
            page: $page,
            perPage: $perPage,
        );
    }

    public function requestWithdraw(RequestWithdrawDto $dto): int
    {
        Log::info("========== REQUEST WITHDRAW START ==========", (array) $dto);

        DB::select(
            'CALL SP_RequestDeliveryWithdraw(?, ?, ?, @success, @message, @withdrawId)',
            [$dto->deliveryProfileId, $dto->amount, $dto->paymentMethodId]
        );

        $result = DB::selectOne(
            'SELECT @success AS success, @message AS message, @withdrawId AS withdrawId'
        );

        Log::info("REQUEST WITHDRAW RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== REQUEST WITHDRAW SUCCESS ==========");

        return (int) $result->withdrawId;
    }

    public function getPendingCashForLivreur(int $deliveryProfileId): PendingCashSummaryDto
    {
        Log::info("========== GET PENDING CASH FOR LIVREUR START ==========", ['deliveryProfileId' => $deliveryProfileId]);

        $rows = DB::select(
            'SELECT dcc.DeliveryID, d.OrderID, dcc.CollectedAmount, dcc.CollectedAt
         FROM DeliveryCashCollections dcc
         INNER JOIN Deliveries d ON d.DeliveryID = dcc.DeliveryID
         WHERE dcc.DeliveryProfileID = ? AND dcc.IsCollected = 1 AND dcc.IsRemitted = 0
         ORDER BY dcc.CollectedAt ASC',
            [$deliveryProfileId]
        );

        $items = array_map(fn($row) => PendingCashItemDto::fromRow($row), $rows);
        $totalDue = array_reduce($items, fn($carry, $i) => $carry + $i->collectedAmount, 0.0);

        Log::info("GET PENDING CASH FOR LIVREUR RESULT", ['count' => count($items), 'totalDue' => $totalDue]);

        return new PendingCashSummaryDto(items: $items, totalDue: $totalDue);
    }
}
