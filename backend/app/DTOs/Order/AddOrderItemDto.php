<?php
// app/DTOs/Order/AddOrderItemDto.php
namespace App\DTOs\Order;

class AddOrderItemDto
{
    public function __construct(
        public readonly int $orderId,
        public readonly int $productId,
        public readonly int $quantity,
        public readonly ?int $combinationId,
        public readonly ?int $promotionId,
        public readonly string $userPublicId,
    ) {
    }
}