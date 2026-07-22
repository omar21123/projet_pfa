<?php

namespace App\DTOs\ProductsConfigAttribute;

use Illuminate\Http\Request;

class UpdateProductsConfigAttributeDto
{
    public function __construct(
        public readonly string $name,
        public readonly ?int $unitID,
        public readonly int $displayOrder,
    ) {
    }

    public static function fromRequest(Request $request, object $existing): self
    {
        return new self(
            name: $request->input('Name', $existing->Name),
            unitID: $request->filled('UnitID') ? (int) $request->input('UnitID') : $existing->UnitID,
            displayOrder: $request->filled('DisplayOrder') ? (int) $request->input('DisplayOrder') : (int) $existing->DisplayOrder,
        );
    }
}