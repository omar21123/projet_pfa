<?php

namespace App\Services;

use App\DTOs\ProductModel\CreateProductModelDto;
use App\DTOs\ProductModel\UpdateProductModelDto;
use App\Repositories\Interface\ProductModelRepositoryInterface;
use App\Services\Interface\ProductModelServiceInterface;

class ProductModelService implements ProductModelServiceInterface
{
    public function __construct(
        private ProductModelRepositoryInterface $productModelRepository
    ) {}

    public function create(CreateProductModelDto $dto): ?object
    {
        return $this->productModelRepository->create($dto);
    }

    public function createByInfo(int $brandID, string $name): int
    {
        return $this->productModelRepository->createByInfo($brandID, $name);
    }

    public function update(int $id, UpdateProductModelDto $dto): bool
    {
        return $this->productModelRepository->update($id, $dto);
    }

    public function findById(int $id): ?object
    {
        return $this->productModelRepository->findById($id);
    }

    public function existsById(int $id): bool
    {
        return $this->productModelRepository->existsById($id);
    }

    public function existsByNameForBrand(int $brandID, string $name): bool
    {
        return $this->productModelRepository->existsByNameForBrand($brandID, $name);
    }

    public function disable(int $id): bool
    {
        return $this->productModelRepository->disable($id);
    }

    public function enable(int $id): bool
    {
        return $this->productModelRepository->enable($id);
    }

    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        return $this->productModelRepository->getAllForAdmin($filters, $page, $perPage);
    }

    public function getAllPublic(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        return $this->productModelRepository->getAllPublic($filters, $page, $perPage);
    }
}