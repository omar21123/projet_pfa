<?php
namespace App\Services\Interface;

use App\DTOs\Admin\CreateAdminDto;

interface AdminServiceInterface
{
     public function registerAdmin(
    CreateAdminDto $dto,
    string $tokenHash,
    ?string $ipAddress,
    int $ttl
): string;
}