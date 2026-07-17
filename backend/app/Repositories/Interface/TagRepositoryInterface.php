<?php

namespace App\Repositories\Interface;

use App\DTOs\Tag\CreateTagDto;
use App\DTOs\Tag\UpdateTagDto;

interface TagRepositoryInterface
{
    public function create(CreateTagDto $dto): object|null;
    public function findById(int $id): object|null;
    public function update(int $id, UpdateTagDto $dto): bool;
    public function updateStatus(int $id, bool $isActive): bool;
    public function delete(int $id): bool;
    public function existsById(int $id): bool;
    public function existsByName(string $name): bool;
    public function getAll(array $filters = [], int $page = 1, int $perPage = 20): array;
    public function createByName(string $name): int;
}