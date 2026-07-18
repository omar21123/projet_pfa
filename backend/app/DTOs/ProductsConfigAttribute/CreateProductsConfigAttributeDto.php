<?php

namespace App\DTOs\ProductsConfigAttribute;

use Illuminate\Http\Request;

class CreateProductsConfigAttributeDto
{
    public function __construct(
        public readonly string $name,
        public readonly ?int $unitID = null,
        public readonly int $displayOrder = 0,
    ) {
    }

    public static function fromRequest(Request $request): self
    {
        return new self(
            name: $request->input('Name'),
            unitID: $request->filled('UnitID') ? (int) $request->input('UnitID') : null,
            displayOrder: $request->filled('DisplayOrder') ? (int) $request->input('DisplayOrder') : 0,
        );
    }
}