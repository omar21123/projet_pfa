<?php

namespace App\DTOs\Product\vendor;

class GetVendorProductsDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly ?int $status = null,
        public readonly ?string $search = null,
        public readonly ?bool $isActive = null,
        public readonly ?bool $isBlocked = null,
        public readonly int $pageNumber = 1,
        public readonly int $pageSize = 20,
    ) {
    }

    public static function fromRequest(array $data, string $userPublicId): self
    {
        return new self(
            userPublicId: $userPublicId,
            status: isset($data['status']) ? (int) $data['status'] : null,
            search: $data['search'] ?? null,
            isActive: isset($data['is_active']) ? filter_var($data['is_active'], FILTER_VALIDATE_BOOLEAN) : null,
            isBlocked: isset($data['is_blocked']) ? filter_var($data['is_blocked'], FILTER_VALIDATE_BOOLEAN) : null,
            pageNumber: (int) ($data['page'] ?? 1),
            pageSize: (int) ($data['per_page'] ?? 20),
        );
    }
}