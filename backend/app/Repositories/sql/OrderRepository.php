<?php
// app/Repositories/sql/OrderRepository.php

namespace App\Repositories\sql;

use App\DTOs\Order\AddOrderItemDto;
use App\DTOs\Order\CreateOrderDto;
use App\DTOs\Order\CustomerOrderDeliveryDto;
use App\DTOs\Order\CustomerOrderDetailsDto;
use App\DTOs\Order\CustomerOrderItemDto;
use App\DTOs\Order\DeliveryStatusHistoryItemDto;
use App\DTOs\Order\OrderItemResultDto;
use App\DTOs\Order\OrderResultDto;
use App\Repositories\Interface\OrderRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\DTOs\Order\OrderDto;

class OrderRepository implements OrderRepositoryInterface
{
    public function create(CreateOrderDto $dto): OrderResultDto
    {
        Log::info("========== CREATE ORDER START ==========", (array) $dto);
        DB::select(
            'CALL SP_CreateOrder(?, ?, ?, ?, ?, @orderId, @orderNumber, @success, @message)',
            [
                $dto->userPublicId,
                $dto->addressId,
                $dto->paymentMethodId,
                $dto->subtotal,
                $dto->notes,
            ]
        );
        $result = DB::selectOne(
            'SELECT @orderId AS orderId, @orderNumber AS orderNumber, @success AS success, @message AS message'
        );

        Log::info("CREATE ORDER RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== CREATE ORDER SUCCESS ==========");

        return OrderResultDto::fromOutput($result);
    }
    public function addItem(AddOrderItemDto $dto): OrderItemResultDto
    {
        Log::info("========== ADD ORDER ITEM START ==========", (array) $dto);

        DB::select(
            'CALL SP_CreateOrderItem(?, ?, ?, ?, ?, ?, @orderItemId, @success, @message)',
            [
                $dto->orderId,
                $dto->productId,
                $dto->quantity,
                $dto->combinationId,
                $dto->promotionId,
                $dto->userPublicId,
            ]
        );

        $result = DB::selectOne(
            'SELECT @orderItemId AS orderItemId, @success AS success, @message AS message'
        );

        Log::info("ADD ORDER ITEM RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        return OrderItemResultDto::fromOutput($result);
    }

    public function recalculateTotals(int $orderId): void
    {
        Log::info("RECALCULATE ORDER TOTALS", ['orderId' => $orderId]);

        DB::select('CALL SP_RecalculateOrderTotals(?, @success, @message)', [
            $orderId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        Log::info("RECALCULATE ORDER TOTALS RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }
    }

    public function findById(int $orderId): OrderDto
    {
        $rows = DB::select('CALL SP_GetOrderById(?)', [$orderId]);

        if (empty($rows)) {
            throw new BusinessValidationException('Commande introuvable.', 404);
        }

        return OrderDto::fromRow($rows[0]);
    }
    public function getCustomerOrderDetails(int $orderId, int $userId): CustomerOrderDetailsDto
    {
        Log::info("========== GET CUSTOMER ORDER DETAILS START ==========", [
            'orderId' => $orderId,
            'userId' => $userId,
        ]);

        // ---- 1) Order header + ownership check ----
        $orderRow = DB::selectOne(
            "SELECT
            o.OrderID, o.OrderNumber, o.Subtotal, o.ShippingFee, o.Discount, o.Tax, o.Total,
            o.Currency, o.Notes, o.OrderedAt, o.UpdatedAt,
            os.Code AS OrderStatusCode, os.Name AS OrderStatusName,

            ba.AddressID AS BillingAddressID, ba.AddressLine1 AS BillingAddressLine1,
            ba.City AS BillingCity, ba.Region AS BillingRegion, ba.Country AS BillingCountry,
            ba.Latitude AS BillingLatitude, ba.Longitude AS BillingLongitude,

            sa.AddressID AS ShippingAddressID, sa.AddressLine1 AS ShippingAddressLine1,
            sa.City AS ShippingCity, sa.Region AS ShippingRegion, sa.Country AS ShippingCountry,
            sa.Latitude AS ShippingLatitude, sa.Longitude AS ShippingLongitude

        FROM Orders o
        INNER JOIN OrderStatus os ON os.OrderStatusID = o.OrderStatusID
        INNER JOIN Addresses ba   ON ba.AddressID = o.BillingAddressID
        INNER JOIN Addresses sa   ON sa.AddressID = o.ShippingAddressID
        WHERE o.OrderID = ?
          AND o.UserID = ?
        LIMIT 1",
            [$orderId, $userId]
        );

        if (!$orderRow) {
            throw new BusinessValidationException('Commande introuvable.', 404);
        }

        $orderDetails = CustomerOrderDetailsDto::fromRow($orderRow);

        // ---- 2) Items, joined to Products + vendor ----
        $itemRows = DB::select(
            "SELECT
            oi.OrderItemID, oi.ProductID, p.Name AS ProductName, p.Barcode,
            (SELECT pr.ResourcesPath
             FROM ProductResources pr
             INNER JOIN ResourcesRoles rr ON rr.RoleID = pr.ResourceRoleID
             WHERE pr.ProductID = p.ProductID AND rr.label = 'Cover'
             LIMIT 1) AS ProductImage,

            oi.ProductVariantID,
            oi.VendorProfileID, vp.StoreName,
            vu.Email AS VendorEmail, vu.PhoneNumber AS VendorPhone, vu.DisplayName AS VendorName,

            oi.Quantity, oi.UnitPrice, oi.Discount, oi.Tax, oi.Total,

            di.DeliveryID

        FROM OrderItems oi
        INNER JOIN Products p        ON p.ProductID = oi.ProductID
        INNER JOIN VendorProfiles vp ON vp.VendorProfileID = oi.VendorProfileID
        INNER JOIN Users vu          ON vu.UserID = vp.UserID
        LEFT JOIN DeliveryItems di   ON di.OrderItemID = oi.OrderItemID
        WHERE oi.OrderID = ?",
            [$orderId]
        );

        $orderDetails->items = array_map(fn($row) => CustomerOrderItemDto::fromRow($row), $itemRows);

        // ---- 3) Deliveries (per vendor group) ----
        $deliveryRows = DB::select(
            "SELECT
            d.DeliveryID, d.VendorProfileID, vp.StoreName,
            ds.Code AS StatusCode, ds.Name AS StatusName,
            d.DeliveryFee, d.Notes,

            af.AddressID AS FromAddressID, af.AddressLine1 AS FromAddressLine1,
            af.City AS FromCity, af.Region AS FromRegion, af.Country AS FromCountry,
            af.Latitude AS FromLatitude, af.Longitude AS FromLongitude,

            at.AddressID AS ToAddressID, at.AddressLine1 AS ToAddressLine1,
            at.City AS ToCity, at.Region AS ToRegion, at.Country AS ToCountry,
            at.Latitude AS ToLatitude, at.Longitude AS ToLongitude,

            dp.DeliveryProfileID,
            u.DisplayName AS LivreurName, u.PhoneNumber AS LivreurPhone, u.AvatarURL AS LivreurAvatarURL,
            dp.VehicleType, dp.LicensePlate, dp.Rating AS LivreurRating,
            dp.CurrentLatitude AS LivreurLatitude, dp.CurrentLongitude AS LivreurLongitude,

            d.RequestedAt, d.AcceptedAt, d.PickedUpAt, d.DeliveredAt, d.CancelledAt

        FROM Deliveries d
        INNER JOIN DeliveryStatuses ds ON ds.DeliveryStatusID = d.DeliveryStatusID
        INNER JOIN VendorProfiles vp   ON vp.VendorProfileID = d.VendorProfileID
        INNER JOIN Addresses af        ON af.AddressID = d.AddressFromID
        INNER JOIN Addresses at        ON at.AddressID = d.AddressToID
        LEFT JOIN DeliveryProfiles dp  ON dp.DeliveryProfileID = d.DeliveryProfileID
        LEFT JOIN Users u              ON u.UserID = dp.UserID
        WHERE d.OrderID = ?",
            [$orderId]
        );

        $deliveries = [];
        foreach ($deliveryRows as $row) {
            $deliveries[(int) $row->DeliveryID] = CustomerOrderDeliveryDto::fromRow($row);
        }

        // ---- 4) Status history, grouped into each delivery ----
        if (!empty($deliveries)) {
            $historyRows = DB::select(
                "SELECT
                dsh.DeliveryID,
                ds.Code AS StatusCode, ds.Name AS StatusName,
                dsh.Latitude, dsh.Longitude, dsh.ChangedAt
            FROM DeliveryStatusHistory dsh
            INNER JOIN DeliveryStatuses ds ON ds.DeliveryStatusID = dsh.DeliveryStatusID
            INNER JOIN Deliveries d        ON d.DeliveryID = dsh.DeliveryID
            WHERE d.OrderID = ?
            ORDER BY dsh.ChangedAt ASC",
                [$orderId]
            );

            foreach ($historyRows as $row) {
                $deliveryId = (int) $row->DeliveryID;
                if (isset($deliveries[$deliveryId])) {
                    $deliveries[$deliveryId]->history[] = DeliveryStatusHistoryItemDto::fromRow($row);
                }
            }
        }

        $orderDetails->deliveries = array_values($deliveries);

        Log::info("GET CUSTOMER ORDER DETAILS RESULT", [
            'items' => count($orderDetails->items),
            'deliveries' => count($orderDetails->deliveries),
        ]);

        return $orderDetails;
    }
}
