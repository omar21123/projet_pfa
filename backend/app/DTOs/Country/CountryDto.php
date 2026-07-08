<?php

namespace App\DTOs\Country;

class CountryDto
{
    public function __construct(
        public readonly int $id,
        public readonly string $name,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            id: (int) $row->CountryID,
            name: $row->Name,
        );
    }

    public function toArray(): array
    {
        return [
            'id'   => $this->id,
            'name' => $this->name,
        ];
    }
}