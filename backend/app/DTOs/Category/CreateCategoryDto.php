<?php

namespace App\DTOs\Category;

class CreateCategoryDto
{
    public function __construct(
        public string $name,
        public ?int $parentCategoryID = null,
        public ?string $iconURL = null,
    ) {
    }

    public static function fromRequest($request, ?string $iconUrl = null): self
{
    return new self(
        name: $request->validated('Name'),
        parentCategoryID: $request->validated('ParentCategoryID'),
        iconURL: $iconUrl,
    );
}
}