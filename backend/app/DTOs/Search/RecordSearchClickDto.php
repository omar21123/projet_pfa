<?php

namespace App\DTOs\Search;

class RecordSearchClickDto
{
    public function __construct(
        public readonly string $termText,
        public readonly int $productId,
    ) {
    }
}