<?php

namespace App\DTOs\ProductModel;

use Illuminate\Http\Request;

class UpdateProductModelDto
{
    public function __construct(
        public readonly int $brandID,
        public readonly string $name,
        public readonly ?string $code = null,
        public readonly ?string $description = null,
        public readonly ?int $releaseYear = null,
    ) {}

    public static function fromRequest(Request $request): self
    {
        return new self(
            brandID: (int) $request->input('BrandID'),
            name: $request->input('Name'),
            code: $request->input('Code'),
            description: $request->input('Description'),
            releaseYear: $request->filled('ReleaseYear') ? (int) $request->input('ReleaseYear') : null,
        );
    }
}