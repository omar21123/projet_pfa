<?php
namespace App\DTOs\Category;

class CreateCategoryDto
{
    public function __construct(
        public string $name,
        public ?int $parentCategoryID = null,
        public ?string $iconURL = null,
        public bool $isActive = true,
        public int $displayOrder = 0
    ) {
    }

    public static function fromRequest($request): self
    {
        return new self(
            name: $request->validated('Name'),
            parentCategoryID: $request->validated('ParentCategoryID'),
            iconURL: $request->validated('IconURL'),
            isActive: (bool) $request->validated('IsActive', true),
            displayOrder: (int) $request->validated('DisplayOrder', 0)
        );
    }
}