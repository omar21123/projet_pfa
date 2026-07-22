<?php

namespace App\Services;

use App\DTOs\ProductsConfigAttribute\CreateProductsConfigAttributeDto;
use App\DTOs\ProductsConfigAttribute\UpdateProductsConfigAttributeDto;
use App\Repositories\Interface\ProductsConfigAttributeRepositoryInterface;
use App\Services\Interface\ProductsConfigAttributeServiceInterface;

class ProductsConfigAttributeService implements ProductsConfigAttributeServiceInterface
{
    public function __construct(
        private ProductsConfigAttributeRepositoryInterface $productsConfigAttributeRepository
    ) {}

    public function create(CreateProductsConfigAttributeDto $dto): ?object
    {
        return $this->productsConfigAttributeRepository->create($dto);
    }

    public function createByName(string $name): int
    {
        return $this->productsConfigAttributeRepository->createByName($name);
    }

    public function update(int $id, UpdateProductsConfigAttributeDto $dto): bool
    {
        return $this->productsConfigAttributeRepository->update($id, $dto);
    }

    public function findById(int $id): ?object
    {
        return $this->productsConfigAttributeRepository->findById($id);
    }

    public function existsById(int $id): bool
    {
        return $this->productsConfigAttributeRepository->existsById($id);
    }

    public function existsByName(string $name): bool
    {
        return $this->productsConfigAttributeRepository->existsByName($name);
    }

    public function disable(int $id): bool
    {
        return $this->productsConfigAttributeRepository->disable($id);
    }

    public function enable(int $id): bool
    {
        return $this->productsConfigAttributeRepository->enable($id);
    }

    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        return $this->productsConfigAttributeRepository->getAllForAdmin($filters, $page, $perPage);
    }

    public function getAll(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        return $this->productsConfigAttributeRepository->getAll($filters, $page, $perPage);
    }
}