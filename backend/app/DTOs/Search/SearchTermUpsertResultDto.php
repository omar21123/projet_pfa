<?php

namespace App\DTOs\Search;

class SearchTermUpsertResultDto
{
    public function __construct(
        public readonly int $searchTermId,
        public readonly string $action, // 'INSERTED' | 'UPDATED'
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            searchTermId: (int) $row->SearchTermID,
            action: $row->Action,
        );
    }

    public function wasInserted(): bool
    {
        return $this->action === 'INSERTED';
    }

    public function wasUpdated(): bool
    {
        return $this->action === 'UPDATED';
    }
}