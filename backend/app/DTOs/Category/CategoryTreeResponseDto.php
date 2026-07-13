<?php

namespace App\DTOs\Category;

class CategoryTreeResponseDto
{
    public function __construct(
        public int $id,
        public string $name,
        public string $slug,
        public ?string $parentCategoryName,
        public ?string $iconURL,
        public bool $isActive,
        public int $displayOrder,
        public string $createdAt,
        public string $updatedAt,
        public int $directChildrenCount,
        public int $totalProductsCount,
        public int $directProductsCount,
        public array $children = [],
    ) {
    }

    public static function fromModel(object $model): self
    {
        return new self(
            id: $model->CategoryID,
            name: $model->Name,
            slug: $model->Slug,
            parentCategoryName: $model->ParentCategoryName ?? null,
            iconURL: $model->IconURL,
            isActive: (bool) $model->IsActive,
            displayOrder: $model->DisplayOrder,
            createdAt: $model->CreatedAt,
            updatedAt: $model->UpdatedAt,
            directChildrenCount: (int) $model->DirectChildrenCount,
            totalProductsCount: (int) $model->TotalProductsCount,
            directProductsCount: (int) $model->DirectProductsCount,
            children: []
        );
    }
}