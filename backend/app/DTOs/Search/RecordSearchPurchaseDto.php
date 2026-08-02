<?php

namespace App\DTOs\Search;

class RecordSearchPurchaseDto
{
    public function __construct(
        public readonly string $termText,
        public readonly int $productId,
    ) {}
}