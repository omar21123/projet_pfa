<?php

namespace App\Services;

use App\DTOs\Category\CategoryFilterDto;
use App\Services\Interface\CategoryServiceInterface;
use App\Repositories\Interface\CategoryRepositoryInterface;
use App\DTOs\Category\CreateCategoryDto;
use App\DTOs\Category\CategoryResponseDto;
use App\DTOs\Category\CategoryTreeResponseDto;
use Illuminate\Support\Collection;
use App\DTOs\Category\UpdateCategoryDto;
use App\Exceptions\BusinessValidationException;

class CategoryService implements CategoryServiceInterface
{
    public function __construct(
        protected CategoryRepositoryInterface $categoryRepository
    ) {
    }

    public function createCategory(CreateCategoryDto $dto): CategoryResponseDto
    {
        $category = $this->categoryRepository->create($dto);
        return CategoryResponseDto::fromModel($category);
    }
    public function categoryExists(int $id): bool
    {
        return $this->categoryRepository->existsById($id);
    }

    public function categoryExistsByName(string $name): bool
    {
        return $this->categoryRepository->existsByName($name);
    }
    public function getRootCategories(CategoryFilterDto $filters): array
    {
        $result = $this->categoryRepository->getRootCategories(
            $filters->toArray(),
            $filters->page,
            $filters->perPage
        );

        $result['data'] = collect($result['data'])
            ->map(fn($cat) => CategoryTreeResponseDto::fromModel($cat))
            ->all();

        return $result;
    }

    public function getChildren(int $parentId, CategoryFilterDto $filters): array
    {
        if (!$this->categoryRepository->existsById($parentId)) {
            throw new \App\Exceptions\BusinessValidationException('Catégorie parente introuvable.', 404);
        }

        $result = $this->categoryRepository->getChildren(
            $parentId,
            $filters->toArray(),
            $filters->page,
            $filters->perPage
        );

        $result['data'] = collect($result['data'])
            ->map(fn($cat) => CategoryTreeResponseDto::fromModel($cat))
            ->all();

        return $result;
    }
    public function deactivateSubtree(int $id): bool
    {
        if (!$this->categoryRepository->existsById($id)) {
            throw new BusinessValidationException('Catégorie introuvable.', 404);
        }

        return $this->categoryRepository->propagateInactivation($id);
    }


    public function updateCategory(int $id, UpdateCategoryDto $dto): bool
    {
        return $this->categoryRepository->update($id, $dto);
    }

    public function updateCategoryStatus(int $id, bool $isActive): bool
    {
        return $this->categoryRepository->updateStatus($id, $isActive);
    }

    public function deleteCategory(int $id): bool
    {
        return $this->categoryRepository->delete($id);
    }
    public function findById(int $id): object|null
    {
        return $this->categoryRepository->findById($id);
    }
    public function activateCategory(int $id): bool
    {
        if (!$this->categoryRepository->existsById($id)) {
            throw new BusinessValidationException('Catégorie introuvable.', 404);
        }

        return $this->categoryRepository->activate($id);
    }
    public function getNavbarCategories(): array
    {
        return $this->categoryRepository->getNavbarCategories();
    }
}
