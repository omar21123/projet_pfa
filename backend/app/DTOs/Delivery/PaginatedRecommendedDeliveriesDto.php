<?php
// app/DTOs/Delivery/PaginatedRecommendedDeliveriesDto.php

namespace App\DTOs\Delivery;

class PaginatedRecommendedDeliveriesDto
{
    /** @param RecommendedDeliveryItemDto[] $data */
    public function __construct(
        public readonly array $data,
        public readonly int $total,
        public readonly int $page,
        public readonly int $perPage,
    ) {
    }

    public function toArray(): array
    {
        return [
            'data' => array_map(fn($item) => $item->toArray(), $this->data),
            'meta' => [
                'total'     => $this->total,
                'page'      => $this->page,
                'page_size' => $this->perPage,
                'last_page' => $this->perPage > 0 ? (int) ceil($this->total / $this->perPage) : 1,
            ],
        ];
    }
}