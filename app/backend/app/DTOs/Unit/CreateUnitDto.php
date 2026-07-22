<?php

namespace App\DTOs\Unit;

use Illuminate\Http\Request;

class CreateUnitDto
{
    public function __construct(
        public readonly string $name,
        public readonly string $symbol,
        public readonly int $displayOrder = 0,
    ) {}

    public static function fromRequest(Request $request): self
    {
        return new self(
            name: $request->input('Name'),
            symbol: $request->input('Symbol'),
            displayOrder: $request->filled('DisplayOrder') ? (int) $request->input('DisplayOrder') : 0,
        );
    }
}