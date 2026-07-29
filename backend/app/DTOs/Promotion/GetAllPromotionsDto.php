<?php

namespace App\DTOs\Promotion;

class GetAllPromotionsDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly ?string $statusCode,
        public readonly ?string $scopeTypeCode,
        public readonly ?bool $isActive,
        public readonly int $page,
        public readonly int $pageSize,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['UserPublicID'],
            statusCode: $data['StatusCode'] ?? null,
            scopeTypeCode: $data['ScopeTypeCode'] ?? null,
            isActive: isset($data['IsActive']) ? (bool) $data['IsActive'] : null,
            page: (int) ($data['Page'] ?? 1),
            pageSize: (int) ($data['PageSize'] ?? 20),
        );
    }
}