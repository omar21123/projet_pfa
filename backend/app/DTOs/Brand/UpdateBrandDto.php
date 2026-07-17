<?php

namespace App\DTOs\Brand;

use Illuminate\Http\Request;

class UpdateBrandDto
{
    public function __construct(
        public readonly ?string $name = null,
        public readonly ?string $logoUrl = null,
        public readonly ?string $website = null,
        public readonly ?string $description = null,
        public readonly ?int $countryID = null,
    ) {}

    public static function fromRequest($request, ?string $logoUrl = null, ?object $existingBrand = null): self
    {
        $name = $request->filled('Name') ? $request->input('Name') : ($existingBrand?->Name ?? null);
        $website = $request->filled('Website') ? $request->input('Website') : ($existingBrand?->Website ?? null);
        $description = $request->filled('Description') ? $request->input('Description') : ($existingBrand?->Description ?? null);
        $countryID = $request->filled('CountryID') ? (int) $request->input('CountryID') : ($existingBrand?->CountryID ?? null);

        return new self(
            name: $name,
            logoUrl: $logoUrl,
            website: $website,
            description: $description,
            countryID: $countryID,
        );
    }
}