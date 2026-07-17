<?php

namespace App\Services\Interface;

use App\DTOs\Unit\CreateUnitDto;
use App\DTOs\Unit\UpdateUnitDto;

interface UnitServiceInterface
{
    public function create(CreateUnitDto $dto): ?object;
    public function update(int $id, UpdateUnitDto $dto): bool;
    public function findById(int $id): ?object;
    public function existsById(int $id): bool;
    public function existsByName(string $name): bool;
    public function disable(int $id): bool;
    public function enable(int $id): bool;
    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array;
    public function getAllPublic(array $filters = [], int $page = 1, int $perPage = 20): array;
}