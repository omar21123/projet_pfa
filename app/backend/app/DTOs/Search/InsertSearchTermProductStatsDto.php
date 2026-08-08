<?php

namespace App\DTOs\Search;

class InsertSearchTermProductStatsDto
{
    public function __construct(
        public readonly int $searchTermId,
        public readonly int $productId,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            searchTermId: $data['searchTermId'],
            productId: $data['productId'],
        );
    }
}