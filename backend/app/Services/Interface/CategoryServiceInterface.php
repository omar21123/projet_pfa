<?php
namespace App\Services\Interface;

use App\DTOs\Category\CategoryFilterDto;
use App\DTOs\Category\CreateCategoryDto;
use App\DTOs\Category\CategoryResponseDto;
use Illuminate\Support\Collection;
use App\DTOs\Category\UpdateCategoryDto;


interface CategoryServiceInterface
{
    public function createCategory(CreateCategoryDto $dto): CategoryResponseDto;
    public function updateCategory(int $id, UpdateCategoryDto $dto): bool;
    public function updateCategoryStatus(int $id, bool $isActive): bool;
    public function deleteCategory(int $id): bool;
    public function findById(int $id): object|null;
    public function categoryExists(int $id): bool;
    public function categoryExistsByName(string $name): bool;
    public function getRootCategories(CategoryFilterDto $filters): array;
    public function getChildren(int $parentId, CategoryFilterDto $filters): array;
    public function deactivateSubtree(int $id): bool;
    public function activateCategory(int $id): bool;
    public function  getNavbarCategories(): array;

}