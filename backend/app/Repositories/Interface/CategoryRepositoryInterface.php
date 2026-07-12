<?php
namespace App\Repositories\Interface;

use App\DTOs\Category\CreateCategoryDto;
use Illuminate\Support\Collection;
use App\DTOs\Category\UpdateCategoryDto;

interface CategoryRepositoryInterface
{
    public function create(CreateCategoryDto $dto): object|null;
    public function getAllTree(): Collection;
    public function findById(int $id): object|null;
    public function update(int $id, UpdateCategoryDto $dto): bool;
    public function updateStatus(int $id, bool $isActive): bool;
    public function delete(int $id): bool;
}