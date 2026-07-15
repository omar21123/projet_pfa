<?php
namespace App\DTOs\Category;

class UpdateCategoryDto
{
    public function __construct(
        public string $name,
        public ?string $iconURL = null,
        public int $displayOrder = 0,
        public bool $isActive = true
    ) {
    }

    public static function fromRequest($request): self
    {
        return new self(
            name: $request->validated('Name'),
            iconURL: $request->validated('IconURL'),
            displayOrder: (int) $request->validated('DisplayOrder', 0),
            isActive: (bool) $request->validated('IsActive', true)
        );
    }
}