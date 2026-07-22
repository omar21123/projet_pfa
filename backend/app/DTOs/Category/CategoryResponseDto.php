<?php
namespace App\DTOs\Category;

class CategoryResponseDto
{
    public function __construct(
        public int $id,
        public string $name,
        public string $slug,
        public ?int $parentCategoryID,
        public ?string $iconURL,
        public bool $isActive,
        public int $displayOrder
    ) {}

    public static function fromModel($model): self
    {
        return new self(
            id: $model->CategoryID,
            name: $model->Name,
            slug: $model->Slug,
            parentCategoryID: $model->ParentCategoryID,
            iconURL: $model->IconURL,
            isActive: (bool) $model->IsActive,
            displayOrder: $model->DisplayOrder
        );
    }
}