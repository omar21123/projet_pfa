<?php
// app/DTOs/Delivery/PaginatedWithdrawHistoryDto.php
namespace App\DTOs\Delivery;

class PaginatedWithdrawHistoryDto
{
    public function __construct(
        public readonly array $data,
        public readonly int $total,
        public readonly int $page,
        public readonly int $perPage,
    ) {}

    public function toArray(): array
    {
        return [
            'data' => array_map(fn($i) => $i->toArray(), $this->data),
            'meta' => [
                'total'     => $this->total,
                'page'      => $this->page,
                'page_size' => $this->perPage,
                'last_page' => (int) ceil($this->total / max($this->perPage, 1)),
            ],
        ];
    }
}