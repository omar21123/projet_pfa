<?php

namespace App\Services\Interface;

use App\DTOs\ProductModel\CreateProductModelDto;
use App\DTOs\ProductModel\UpdateProductModelDto;

interface ProductModelServiceInterface
{
    public function create(CreateProductModelDto $dto): ?object;
    public function createByInfo(int $brandID, string $name): int;
    public function update(int $id, UpdateProductModelDto $dto): bool;
    public function findById(int $id): ?object;
    public function existsById(int $id): bool;
    public function existsByNameForBrand(int $brandID, string $name): bool;
    public function disable(int $id): bool;
    public function enable(int $id): bool;
    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array;
    public function getAllPublic(array $filters = [], int $page = 1, int $perPage = 20): array;
}