<?php
// app/DTOs/Order/GetCustomerOrdersDto.php

namespace App\DTOs\Order;

class GetCustomerOrdersDto
{
    public function __construct(
        public readonly int $userId,
        public readonly ?string $statusCode,
        public readonly int $page,
        public readonly int $perPage,
    ) {
    }

    public static function fromRequest(array $validated, int $userId): self
    {
        return new self(
            userId: $userId,
            statusCode: $validated['status'] ?? null,
            page: (int) ($validated['page'] ?? 1),
            perPage: (int) ($validated['per_page'] ?? 20),
        );
    }
}