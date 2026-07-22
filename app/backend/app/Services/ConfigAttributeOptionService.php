<?php

namespace App\Services;

use App\DTOs\ConfigAttributeOption\CreateConfigAttributeOptionDto;
use App\DTOs\ConfigAttributeOption\UpdateConfigAttributeOptionDto;
use App\Repositories\Interface\ConfigAttributeOptionRepositoryInterface;
use App\Services\Interface\ConfigAttributeOptionServiceInterface;

class ConfigAttributeOptionService implements ConfigAttributeOptionServiceInterface
{
    public function __construct(
        private ConfigAttributeOptionRepositoryInterface $configAttributeOptionRepository
    ) {}

    public function create(CreateConfigAttributeOptionDto $dto): ?object
    {
        return $this->configAttributeOptionRepository->create($dto);
    }

    public function createByName(int $attributeID, string $optionLabel): int
    {
        return $this->configAttributeOptionRepository->createByName($attributeID, $optionLabel);
    }

    public function update(int $id, UpdateConfigAttributeOptionDto $dto): bool
    {
        return $this->configAttributeOptionRepository->update($id, $dto);
    }

    public function findById(int $id): ?object
    {
        return $this->configAttributeOptionRepository->findById($id);
    }

    public function existsById(int $id): bool
    {
        return $this->configAttributeOptionRepository->existsById($id);
    }

    public function existsByName(int $attributeID, string $optionLabel): bool
    {
        return $this->configAttributeOptionRepository->existsByName($attributeID, $optionLabel);
    }

    public function disable(int $id): bool
    {
        return $this->configAttributeOptionRepository->disable($id);
    }

    public function enable(int $id): bool
    {
        return $this->configAttributeOptionRepository->enable($id);
    }

    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        return $this->configAttributeOptionRepository->getAllForAdmin($filters, $page, $perPage);
    }

    public function getAll(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        return $this->configAttributeOptionRepository->getAll($filters, $page, $perPage);
    }
    public function getAllOptionsByAttributeID(int $attributeID): array
    {
        return $this->configAttributeOptionRepository->getAllOptionsByAttributeID($attributeID);
    }
}