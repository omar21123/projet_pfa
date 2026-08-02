<?php

namespace App\DTOs\Product;

class ProductInfoConfigOptionDto
{
    public function __construct(
        public readonly int $optionId,
        public readonly string $optionLabel,
        public readonly string $optionValue,
        public readonly bool $isDefault,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            optionId: (int) $row->OptionID,
            optionLabel: $row->OptionLabel,
            optionValue: $row->OptionValue,
            isDefault: (bool) $row->IsDefault,
        );
    }

    public function toArray(): array
    {
        return [
            'OptionID'    => $this->optionId,
            'OptionLabel' => $this->optionLabel,
            'OptionValue' => $this->optionValue,
            'isDefault'   => $this->isDefault,
        ];
    }
}