<?php

namespace App\Services\Interface;

use App\DTOs\ProductsConfigAttribute\CreateProductsConfigAttributeDto;
use App\DTOs\ProductsConfigAttribute\UpdateProductsConfigAttributeDto;

interface ProductsConfigAttributeServiceInterface
{
    public function create(CreateProductsConfigAttributeDto $dto): ?object;

    public function createByName(string $name): int;

    public function update(int $id, UpdateProductsConfigAttributeDto $dto): bool;

    public function findById(int $id): ?object;

    public function existsById(int $id): bool;

    public function existsByName(string $name): bool;

    public function disable(int $id): bool;

    public function enable(int $id): bool;

    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array;

    public function getAll(array $filters = [], int $page = 1, int $perPage = 20): array;
}