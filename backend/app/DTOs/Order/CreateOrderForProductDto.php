<?php
// app/DTOs/Order/CreateOrderForProductDto.php
namespace App\DTOs\Order;

class CreateOrderForProductDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly int $addressId,
        public readonly int $paymentMethodId,
        public readonly int $productId,
        public readonly int $quantity,
        public readonly ?int $combinationId = null,
        public readonly ?int $promotionId = null,
        public readonly ?string $notes = null,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['UserPublicID'],
            addressId: $data['AddressID'],
            paymentMethodId: $data['PaymentMethodID'],
            productId: $data['ProductID'],
            quantity: $data['Quantity'],
            combinationId: $data['CombinationID'] ?? null,
            promotionId: $data['PromotionID'] ?? null,
            notes: $data['Notes'] ?? null,
        );
    }
}