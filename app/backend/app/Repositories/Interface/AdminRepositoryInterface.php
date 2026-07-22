<?php

namespace App\Repositories\Interface;

use App\DTOs\Admin\CreateAdminDto;

interface AdminRepositoryInterface
{
    public function createAdminUser(
    CreateAdminDto $dto,
    string $passwordHash,
    string $tokenHash,
    ?string $ipAddress,
    int $ttl
): string;
}