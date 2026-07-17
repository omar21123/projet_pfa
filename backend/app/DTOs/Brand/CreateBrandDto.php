<?php

namespace App\DTOs\Brand;

use Illuminate\Http\Request;

class CreateBrandDto
{
    public function __construct(
        public readonly string $name,
        public readonly ?string $logoUrl = null,
        public readonly ?string $website = null,
        public readonly ?string $description = null,
        public readonly ?int $countryID = null,
    ) {}

    public static function fromRequest($request, ?string $logoUrl = null): self
    {
        return new self(
            name: $request->input('Name'),
            logoUrl: $logoUrl,
            website: $request->input('Website'),
            description: $request->input('Description'),
            countryID: $request->filled('CountryID') ? (int) $request->input('CountryID') : null,
        );
    }
}