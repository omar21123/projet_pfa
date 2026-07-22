<?php
namespace App\Repositories\Interface;

use App\DTOs\Category\CreateCategoryDto;
use Illuminate\Support\Collection;
use App\DTOs\Category\UpdateCategoryDto;

interface CategoryRepositoryInterface
{
    public function create(CreateCategoryDto $dto): object|null;
    public function findById(int $id): object|null;
    public function update(int $id, UpdateCategoryDto $dto): bool;
    public function updateStatus(int $id, bool $isActive): bool;
    public function delete(int $id): bool;
    public function existsById(int $id): bool;
    public function existsByName(string $name): bool;
    public function getRootCategories(array $filters = [], int $page = 1, int $perPage = 20): array;
    public function getChildren(int $parentId, array $filters = [], int $page = 1, int $perPage = 50): array;
    public function propagateInactivation(int $id): bool;
    public function activate(int $id): bool;
    public function  getNavbarCategories(): array;
}