<?php

namespace App\DTOs\ConfigAttributeOption;

use Illuminate\Http\Request;

class UpdateConfigAttributeOptionDto
{
    public function __construct(
        public readonly int $productsConfigAttributeID,
        public readonly string $optionLabel,
        public readonly string $optionValue,
        public readonly int $displayOrder,
        public readonly bool $isDefaultForAttribute,
    ) {
    }

    public static function fromRequest(Request $request, object $existing): self
    {
        return new self(
            productsConfigAttributeID: $request->filled('ProductsConfigAttributeID')
                ? (int) $request->input('ProductsConfigAttributeID')
                : (int) $existing->ProductsConfigAttributeID,
            optionLabel: $request->input('OptionLabel', $existing->OptionLabel),
            optionValue: $request->input('OptionValue', $existing->OptionValue),
            displayOrder: $request->filled('DisplayOrder') ? (int) $request->input('DisplayOrder') : (int) $existing->DisplayOrder,
            isDefaultForAttribute: $request->has('IsDefaultForAttribute')
                ? $request->boolean('IsDefaultForAttribute')
                : (bool) $existing->IsDefaultForAttribute,
        );
    }
}