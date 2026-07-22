<?php

namespace App\DTOs\Product;

class PaginatedProductAdminResponseDto
{
    /** @param ProductAdminResponseDto[] $items */
    public function __construct(
        public readonly array $items,
        public readonly int $total,
        public readonly int $page,
        public readonly int $pageSize,
    ) {}

    public function lastPage(): int
    {
        return (int) max(1, ceil($this->total / max(1, $this->pageSize)));
    }

    public function toArray(): array
    {
        return [
            'data' => array_map(fn (ProductAdminResponseDto $p) => $p->toArray(), $this->items),
            'meta' => [
                'total'     => $this->total,
                'page'      => $this->page,
                'page_size' => $this->pageSize,
                'last_page' => $this->lastPage(),
            ],
        ];
    }
}