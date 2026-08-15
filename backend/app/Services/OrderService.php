<?php
// app/Services/OrderService.php

namespace App\Services;

use App\DTOs\Order\AddOrderItemDto;
use App\DTOs\Order\CreateOrderDto;
use App\DTOs\Order\CreateOrderForProductDto;
use App\DTOs\Order\OrderDto;
use App\Repositories\Interface\OrderRepositoryInterface;
use App\Services\Interface\OrderServiceInterface;
use Illuminate\Support\Facades\DB;

class OrderService implements OrderServiceInterface
{
    public function __construct(
        protected OrderRepositoryInterface $orderRepository
    ) {
    }

    public function createOrderFromCart(/* CreateOrderFromCartDto $dto */)
    {
        // TODO: implement once input contract is defined
    }
    public function createOrderForProduct(CreateOrderForProductDto $dto): OrderDto
    {
        
            $orderResult = $this->orderRepository->create(new CreateOrderDto(
                userPublicId: $dto->userPublicId,
                addressId: $dto->addressId,
                paymentMethodId: $dto->paymentMethodId,
                subtotal: 0.00, // placeholder, finalized in step 3
                notes: $dto->notes,
            ));

            $this->orderRepository->addItem(new AddOrderItemDto(
                orderId: $orderResult->orderId,
                productId: $dto->productId,
                quantity: $dto->quantity,
                combinationId: $dto->combinationId,
                promotionId: $dto->promotionId,
                userPublicId: $dto->userPublicId,
            ));

            $this->orderRepository->recalculateTotals($orderResult->orderId);

            return $this->orderRepository->findById($orderResult->orderId);
    }
}
