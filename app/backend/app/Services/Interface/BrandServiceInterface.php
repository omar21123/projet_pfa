<?php

namespace App\Services\Interface;

use App\DTOs\Brand\CreateBrandDto;
use App\DTOs\Brand\UpdateBrandDto;

interface BrandServiceInterface
{
    public function create(CreateBrandDto $dto): ?object;
    public function createByName(string $name): int;
    public function update(int $id, UpdateBrandDto $dto): bool;
    public function findById(int $id): ?object;
    public function existsById(int $id): bool;
    public function existsByName(string $name): bool;
    public function disable(int $id): bool;
    public function enable(int $id): bool;
    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array;
    public function getAllPublic(array $filters = [], int $page = 1, int $perPage = 20): array;
}