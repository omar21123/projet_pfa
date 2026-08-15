<?php
// app/DTOs/Order/OrderItemResultDto.php
namespace App\DTOs\Order;

class OrderItemResultDto
{
    public function __construct(
        public readonly int $orderItemId,
        public readonly string $message,
    ) {
    }

    public static function fromOutput(object $row): self
    {
        return new self(
            orderItemId: (int) $row->orderItemId,
            message: (string) $row->message,
        );
    }
}