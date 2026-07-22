<?php

namespace App\Services;

use App\DTOs\Unit\CreateUnitDto;
use App\DTOs\Unit\UpdateUnitDto;
use App\Repositories\Interface\UnitRepositoryInterface;
use App\Services\Interface\UnitServiceInterface;

class UnitService implements UnitServiceInterface
{
    public function __construct(
        private UnitRepositoryInterface $unitRepository
    ) {}

    public function create(CreateUnitDto $dto): ?object
    {
        return $this->unitRepository->create($dto);
    }

    public function update(int $id, UpdateUnitDto $dto): bool
    {
        return $this->unitRepository->update($id, $dto);
    }

    public function findById(int $id): ?object
    {
        return $this->unitRepository->findById($id);
    }

    public function existsById(int $id): bool
    {
        return $this->unitRepository->existsById($id);
    }

    public function existsByName(string $name): bool
    {
        return $this->unitRepository->existsByName($name);
    }

    public function disable(int $id): bool
    {
        return $this->unitRepository->disable($id);
    }

    public function enable(int $id): bool
    {
        return $this->unitRepository->enable($id);
    }

    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        return $this->unitRepository->getAllForAdmin($filters, $page, $perPage);
    }

    public function getAllPublic(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        return $this->unitRepository->getAllPublic($filters, $page, $perPage);
    }
}