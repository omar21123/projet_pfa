<?php

namespace App\DTOs\Product;

class GetAllProductsAdminDto
{
    public function __construct(
        public readonly ?int $status = null,
        public readonly ?int $vendorId = null,
        public readonly ?int $brandId = null,
        public readonly ?int $modelId = null,
        public readonly ?string $search = null,
        public readonly ?bool $isActive = null,
        public readonly ?bool $isBlocked = null,
        public readonly ?string $dateFrom = null,
        public readonly ?string $dateTo = null,
        public readonly int $pageNumber = 1,
        public readonly int $pageSize = 20,
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            status: isset($data['status']) ? (int) $data['status'] : null,
            vendorId: isset($data['vendor_id']) ? (int) $data['vendor_id'] : null,
            brandId: isset($data['brand_id']) ? (int) $data['brand_id'] : null,
            modelId: isset($data['model_id']) ? (int) $data['model_id'] : null,
            search: $data['search'] ?? null,
            isActive: isset($data['is_active']) ? (bool) $data['is_active'] : null,
            isBlocked: isset($data['is_blocked']) ? (bool) $data['is_blocked'] : null,
            dateFrom: $data['date_from'] ?? null,
            dateTo: $data['date_to'] ?? null,
            pageNumber: isset($data['page']) ? max(1, (int) $data['page']) : 1,
            pageSize: isset($data['per_page']) ? max(1, (int) $data['per_page']) : 20,
        );
    }
}