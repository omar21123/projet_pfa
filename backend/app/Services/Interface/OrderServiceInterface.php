<?php
// app/Repositories/Interface/OrderRepositoryInterface.php

namespace App\Services\Interface;

use App\DTOs\Order\CreateOrderDto;
use App\DTOs\Order\CreateOrderForProductDto;
use App\DTOs\Order\CreateOrderFromCartDto;
use App\DTOs\Order\CustomerOrderDetailsDto;
use App\DTOs\Order\GetCustomerOrdersDto;
use App\DTOs\Order\OrderDto;
use App\DTOs\Order\OrderResultDto;
use App\DTOs\Order\PaginatedCustomerOrdersDto;

interface OrderServiceInterface
{
        public function createOrderFromCart(CreateOrderFromCartDto $dto): OrderDto;
        public function createOrderForProduct(CreateOrderForProductDto $dto): OrderDto;
        public function getCustomerOrderDetails(int $orderId, int $userId): CustomerOrderDetailsDto;
        public function getCustomerOrders(GetCustomerOrdersDto $dto): PaginatedCustomerOrdersDto;
}
