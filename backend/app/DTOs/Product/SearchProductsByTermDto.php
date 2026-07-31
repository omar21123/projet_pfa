<?php

namespace App\DTOs\Product;

class SearchProductsByTermDto
{
    public function __construct(
        public readonly string $query,
        public readonly ?string $userPublicId,
        public readonly int $pageNumber,
        public readonly int $pageSize,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            query: $data['Query'],
            userPublicId: $data['UserPublicID'] ?? null,
            pageNumber: (int) ($data['PageNumber'] ?? 1),
            pageSize: (int) ($data['PageSize'] ?? 20),
        );
    }
}