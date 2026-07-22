<?php

namespace App\Repositories\Interface;

use App\DTOs\ConfigAttributeOption\CreateConfigAttributeOptionDto;
use App\DTOs\ConfigAttributeOption\UpdateConfigAttributeOptionDto;

interface ConfigAttributeOptionRepositoryInterface
{
    public function create(CreateConfigAttributeOptionDto $dto): ?object;

    public function createByName(int $attributeID, string $optionLabel): int;

    public function update(int $id, UpdateConfigAttributeOptionDto $dto): bool;

    public function findById(int $id): ?object;

    public function existsById(int $id): bool;

    public function existsByName(int $attributeID, string $optionLabel): bool;

    public function disable(int $id): bool;

    public function enable(int $id): bool;

    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array;

    public function getAll(array $filters = [], int $page = 1, int $perPage = 20): array;
    public function getAllOptionsByAttributeID(int $attributeID): array;
}