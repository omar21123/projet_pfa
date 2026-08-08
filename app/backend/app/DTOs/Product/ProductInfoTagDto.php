<?php

namespace App\DTOs\Product;

class ProductInfoTagDto
{
    public function __construct(
        public readonly int $tagId,
        public readonly string $tagName,
        public readonly ?string $color = null,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            tagId: (int) $row->TagID,
            tagName: $row->Name,
            color: $row->Color,
        );
    }

    public function toArray(): array
    {
        return [
            'TagID'   => $this->tagId,
            'Color'   => $this->color,
            'TagName' => $this->tagName,
        ];
    }
}