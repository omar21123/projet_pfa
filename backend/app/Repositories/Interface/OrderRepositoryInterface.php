<?php
// app/Repositories/Interface/OrderRepositoryInterface.php

namespace App\Repositories\Interface;

use App\DTOs\Order\AddOrderItemDto;
use App\DTOs\Order\CreateOrderDto;
use App\DTOs\Order\CustomerOrderDetailsDto;
use App\DTOs\Order\OrderDto;
use App\DTOs\Order\OrderItemResultDto;
use App\DTOs\Order\OrderResultDto;

interface OrderRepositoryInterface
{
    public function create(CreateOrderDto $dto): OrderResultDto;
    public function addItem(AddOrderItemDto $dto): OrderItemResultDto;
    public function recalculateTotals(int $orderId): void;
    public function findById(int $orderId): OrderDto;
    public function getCustomerOrderDetails(int $orderId, int $userId): CustomerOrderDetailsDto;
}
