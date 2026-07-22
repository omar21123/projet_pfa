<?php

namespace App\DTOs\ConfigAttributeOption;

use Illuminate\Http\Request;

class CreateConfigAttributeOptionDto
{
    public function __construct(
        public readonly int $productsConfigAttributeID,
        public readonly string $optionLabel,
        public readonly string $optionValue,
        public readonly int $displayOrder = 0,
        public readonly bool $isDefaultForAttribute = false,
    ) {
    }

    public static function fromRequest(Request $request): self
    {
        return new self(
            productsConfigAttributeID: (int) $request->input('ProductsConfigAttributeID'),
            optionLabel: $request->input('OptionLabel'),
            optionValue: $request->input('OptionValue'),
            displayOrder: $request->filled('DisplayOrder') ? (int) $request->input('DisplayOrder') : 0,
            isDefaultForAttribute: $request->boolean('IsDefaultForAttribute'),
        );
    }
}