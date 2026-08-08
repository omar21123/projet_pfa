<?php

namespace App\DTOs\Search;

class SearchHistoryItemDto
{
    public function __construct(
        public readonly string $searchText,
        public readonly int $searchCount,
        public readonly string $lastSearchedAt,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            searchText: $row->SearchText,
            searchCount: (int) $row->SearchCount,
            lastSearchedAt: (string) $row->LastSearchedAt,
        );
    }

    public function toArray(): array
    {
        return [
            'text'             => $this->searchText,
            'search_count'     => $this->searchCount,
            'last_searched_at' => $this->lastSearchedAt,
        ];
    }
}