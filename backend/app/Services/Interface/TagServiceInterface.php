<?php

namespace App\Services\Interface;

use App\DTOs\Tag\CreateTagDto;
use App\DTOs\Tag\UpdateTagDto;

interface TagServiceInterface
{
    public function create(CreateTagDto $dto): ?object;
    public function createByName(string $name): int;
    public function findById(int $id): ?object;
    public function update(int $id, UpdateTagDto $dto): bool;
    public function updateStatus(int $id, bool $isActive): bool;
    public function delete(int $id): bool;
    public function existsById(int $id): bool;
    public function existsByName(string $name): bool;
    public function getAll(array $filters = [], int $page = 1, int $perPage = 20): array;
}