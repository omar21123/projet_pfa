<?php

namespace App\DTOs\Product\vendor;

class PaginatedVendorProductResponseDto
{
    /**
     * @param VendorProductItemDto[] $items
     */
    public function __construct(
        public readonly array $items,
        public readonly int $total,
        public readonly int $page,
        public readonly int $pageSize,
    ) {}

    public function toArray(): array
    {
        return [
            'data' => array_map(fn(VendorProductItemDto $item) => $item->toArray(), $this->items),
            'meta' => [
                'total'     => $this->total,
                'page'      => $this->page,
                'page_size' => $this->pageSize,
                'last_page' => $this->pageSize > 0 ? (int) ceil($this->total / $this->pageSize) : 1,
            ],
        ];
    }
}