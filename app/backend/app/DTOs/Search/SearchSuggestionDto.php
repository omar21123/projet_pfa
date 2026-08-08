<?php

namespace App\DTOs\Search;

class SearchSuggestionDto
{
    public function __construct(
        public readonly string $displayText,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(displayText: $row->DisplayText);
    }

    public function toArray(): array
    {
        return ['text' => $this->displayText];
    }
}