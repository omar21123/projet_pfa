<?php

namespace App\Services;

use App\DTOs\Tag\CreateTagDto;
use App\DTOs\Tag\UpdateTagDto;
use App\Repositories\Interface\TagRepositoryInterface;
use App\Services\Interface\TagServiceInterface;

class TagService implements TagServiceInterface
{
    public function __construct(
        private TagRepositoryInterface $tagRepository
    ) {}

    public function create(CreateTagDto $dto): ?object
    {
        return $this->tagRepository->create($dto);
    }

    public function createByName(string $name): int
    {
        return $this->tagRepository->createByName($name);
    }

    public function findById(int $id): ?object
    {
        return $this->tagRepository->findById($id);
    }

    public function update(int $id, UpdateTagDto $dto): bool
    {
        return $this->tagRepository->update($id, $dto);
    }

    public function updateStatus(int $id, bool $isActive): bool
    {
        return $this->tagRepository->updateStatus($id, $isActive);
    }

    public function delete(int $id): bool
    {
        return $this->tagRepository->delete($id);
    }

    public function existsById(int $id): bool
    {
        return $this->tagRepository->existsById($id);
    }

    public function existsByName(string $name): bool
    {
        return $this->tagRepository->existsByName($name);
    }

    public function getAll(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        return $this->tagRepository->getAll($filters, $page, $perPage);
    }
}