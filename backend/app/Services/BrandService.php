<?php

namespace App\Services;

use App\DTOs\Brand\CreateBrandDto;
use App\DTOs\Brand\UpdateBrandDto;
use App\Repositories\Interface\BrandRepositoryInterface;
use App\Services\Interface\BrandServiceInterface;

class BrandService implements BrandServiceInterface
{
    public function __construct(
        private BrandRepositoryInterface $brandRepository
    ) {}

    public function create(CreateBrandDto $dto): ?object
    {
        return $this->brandRepository->create($dto);
    }

    public function createByName(string $name): int
    {
        return $this->brandRepository->createByName($name);
    }

    public function update(int $id, UpdateBrandDto $dto): bool
    {
        return $this->brandRepository->update($id, $dto);
    }

    public function findById(int $id): ?object
    {
        return $this->brandRepository->findById($id);
    }

    public function existsById(int $id): bool
    {
        return $this->brandRepository->existsById($id);
    }

    public function existsByName(string $name): bool
    {
        return $this->brandRepository->existsByName($name);
    }

    public function disable(int $id): bool
    {
        return $this->brandRepository->disable($id);
    }

    public function enable(int $id): bool
    {
        return $this->brandRepository->enable($id);
    }

    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        return $this->brandRepository->getAllForAdmin($filters, $page, $perPage);
    }

    public function getAllPublic(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        return $this->brandRepository->getAllPublic($filters, $page, $perPage);
    }
}