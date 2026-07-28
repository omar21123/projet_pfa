<?php

namespace App\DTOs\Promotion;

class LookupItemDto
{
    public function __construct(
        public readonly int $id,
        public readonly string $code,
        public readonly string $label,
    ) {}

    public static function fromRow(object $row, string $idField): self
    {
        return new self(
            id: (int) $row->{$idField},
            code: $row->Code,
            label: $row->Label,
        );
    }

    public function toArray(): array
    {
        return ['id' => $this->id, 'code' => $this->code, 'label' => $this->label];
    }
}