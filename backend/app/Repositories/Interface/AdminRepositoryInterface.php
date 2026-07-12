<?php

namespace App\Repositories\Interface;

use App\DTOs\Admin\CreateAdminDto;

interface AdminRepositoryInterface
{
    public function createAdmin(CreateAdminDto $dto): object|null;
}