<?php

namespace App\DTOs\Search;

class UpsertSearchTermDto
{
    public function __construct(
        public readonly string $displayText,
        public readonly int $sourceType,
        public readonly ?int $sourceId,
        public readonly int $resultCount,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            displayText: $data['displayText'],
            sourceType: $data['sourceType'],
            sourceId: $data['sourceId'] ?? null,
            resultCount: $data['resultCount'] ?? 0,
        );
    }
}