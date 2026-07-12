<?php
namespace App\Services;

use App\Services\Interface\CategoryServiceInterface;
use App\Repositories\Interface\CategoryRepositoryInterface;
use App\DTOs\Category\CreateCategoryDto;
use App\DTOs\Category\CategoryResponseDto;
use App\DTOs\Category\CategoryTreeResponseDto;
use Illuminate\Support\Collection;
use App\DTOs\Category\UpdateCategoryDto;
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

    public function getCategoryTree(): Collection
    {
        $categories = $this->categoryRepository->getAllTree();
        return $categories->map(fn($cat) => CategoryResponseDto::fromModel($cat));
    }

    /**
     * Reconstruit l'arborescence complète (Catégories -> Sous-catégories)
     */
    public function getCategoryTreeNested(): array
    {
        // 1. Récupération de toutes les catégories (via ton Repository)
        $flatCategories = $this->categoryRepository->getAllTree();

        $dictionary = [];
        $tree = [];

        // 2. On transforme chaque modèle en DTO de type "Arbre" indexé par son ID
        foreach ($flatCategories as $category) {
            $dictionary[$category->CategoryID] = CategoryTreeResponseDto::fromModel($category);
        }

        // 3. On distribue les enfants chez leurs parents respectifs
        foreach ($dictionary as $id => $dto) {
            if ($dto->parentCategoryID === null) {
                // C'est une catégorie racine (Parent de premier niveau)
                $tree[] = $dto;
            } else {
                // C'est une sous-catégorie, on la pousse dans le tableau 'children' de son parent
                if (isset($dictionary[$dto->parentCategoryID])) {
                    $dictionary[$dto->parentCategoryID]->children[] = $dto;
                }
            }
        }

        return $tree;
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
        public function findById(int $id): object|null{
            return $this->categoryRepository->findById($id);
        }

}
