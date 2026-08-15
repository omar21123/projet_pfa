<?php
// app/Services/OrderService.php

namespace App\Services;

use App\Adapters\Payment\PaymentAdapterInterface;
use App\DTOs\Cart\GetCartDto;
use App\DTOs\Delivery\AddOrderItemToDeliveryDto;
use App\DTOs\Order\AddOrderItemDto;
use App\DTOs\Order\CreateOrderDto;
use App\DTOs\Order\CreateOrderForProductDto;
use App\DTOs\Order\CreateOrderFromCartDto;
use App\DTOs\Order\OrderDto;
use App\DTOs\Payment\PayFromOrderDto;
use App\Exceptions\BusinessValidationException;
use App\Repositories\Interface\AddressRepositoryInterface;
use App\Repositories\Interface\OrderRepositoryInterface;
use App\Services\Interface\CartServiceInterface;
use App\Services\Interface\DeliveryServiceInterface;
use App\Services\Interface\OrderServiceInterface;
use App\Services\Interface\PaymentServiceInterface;
use Illuminate\Support\Facades\Log;

class OrderService implements OrderServiceInterface
{
    public function __construct(
        protected OrderRepositoryInterface $orderRepository,
        protected CartServiceInterface $cartService,
        protected PaymentAdapterInterface $paymentAdapter,
        protected PaymentServiceInterface $payment_service,
        protected AddressRepositoryInterface $address_repository,
        protected DeliveryServiceInterface $delivery_service,
    ) {}

    public function createOrderFromCart(CreateOrderFromCartDto $dto): OrderDto
    {
        Log::info("========== CREATE ORDER FROM CART START ==========", [
            'userPublicId' => $dto->userPublicId,
        ]);

        $cartItems = $this->cartService->getCart(new GetCartDto(
            userPublicId: $dto->userPublicId,
        ));

        Log::info("STEP 1 - Cart fetched", [
            'userPublicId' => $dto->userPublicId,
            'itemCount' => count($cartItems),
        ]);

        if (empty($cartItems)) {
            throw new BusinessValidationException('Votre panier est vide.', 422);
        }
        // 2) Create the order shell
        $orderResult = $this->orderRepository->create(new CreateOrderDto(
            userPublicId: $dto->userPublicId,
            addressId: $dto->addressId,
            paymentMethodId: $dto->paymentMethodId,
            subtotal: 0.00, // placeholder, finalized in step 4
            notes: $dto->notes,
        ));

        Log::info("STEP 2 - Order shell created", [
            'orderId' => $orderResult->orderId,
            'orderNumber' => $orderResult->orderNumber,
        ]);

        // 3) Add every cart item as an order item
        foreach ($cartItems as $index => $item) {

            Log::info("STEP 3 - Adding cart item to order", [
                'index' => $index,
                'productId' => $item->productId,
                'combinationId' => $item->combinationId,
                'quantity' => $item->quantity,
                'hasPromotion' => $item->hasPromotion,
            ]);

            $itemDto = $this->orderRepository->addItem(new AddOrderItemDto(
                orderId: $orderResult->orderId,
                productId: $item->productId,
                quantity: (int) $item->quantity,
                combinationId: $item->combinationId ?: null,
                promotionId: $item->hasPromotion ? ($item->promotion?->promotionId ?? null) : null,
                userPublicId: $dto->userPublicId,
            ));

            $deliveryItemDto = new AddOrderItemToDeliveryDto(
                productId: $item->productId,
                orderId: $orderResult->orderId,
                orderItemId: $itemDto->orderItemId,
                addressToId: $dto->addressId,
                notes: $dto->notes,
            );

            $this->delivery_service->addOrderItemToDelivery($deliveryItemDto);
        }

        // 4) Recalculate totals from the items just inserted
        $this->orderRepository->recalculateTotals($orderResult->orderId);

        $this->processPayment($this->orderRepository->findById($orderResult->orderId));

        // 5) Clear the cart only after its payment placeholder succeeds.
        $this->cartService->clearCart($dto->userPublicId);

        Log::info("========== CREATE ORDER FROM CART SUCCESS ==========", [
            'orderId' => $orderResult->orderId,
            'itemCount' => count($cartItems),
        ]);


        return $this->orderRepository->findById($orderResult->orderId);
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

        $itemDto = $this->orderRepository->addItem(new AddOrderItemDto(
            orderId: $orderResult->orderId,
            productId: $dto->productId,
            quantity: $dto->quantity,
            combinationId: $dto->combinationId,
            promotionId: $dto->promotionId,
            userPublicId: $dto->userPublicId,
        ));

        $deliveryItemDto = new AddOrderItemToDeliveryDto(
            productId: $dto->productId,
            orderId: $orderResult->orderId,
            orderItemId: $itemDto->orderItemId,
            addressToId: $dto->addressId,
            notes: $dto->notes,
        );

        $this->delivery_service->addOrderItemToDelivery($deliveryItemDto);
        $this->orderRepository->recalculateTotals($orderResult->orderId);

        $order = $this->orderRepository->findById($orderResult->orderId);

        $this->processPayment($order);

        return $order;
    }
    private function processPayment(OrderDto $order): void
    {
        $authorizedPayment = $this->paymentAdapter->authorize($order);
        $this->paymentAdapter->capture($authorizedPayment);
        $paymentDto = new PayFromOrderDto(
            orderId: $order->orderId,
            paymentMethodId: $order->paymentMethodId,
            transactionId: $authorizedPayment->transactionId,
            providerReference: $authorizedPayment->provider,
        );
        $this->payment_service->payFromOrder($paymentDto);
    }
}
