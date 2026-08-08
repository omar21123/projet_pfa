<?php

namespace App\DTOs\Product;

class PaginatedProductItemResponseDto
{
    public function __construct(
        public readonly array $items,
        public readonly int $total,
        public readonly int $page,
        public readonly int $pageSize,
    ) {}

    public function toArray(): array
    {
        return [
            'items' => array_map(fn(ProductItemDto $p) => $p->toArray(), $this->items),
            'meta' => [
                'total'     => $this->total,
                'page'      => $this->page,
                'page_size' => $this->pageSize,
                'has_more'  => ($this->page * $this->pageSize) < $this->total,
            ],
        ];
    }
}