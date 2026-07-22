<?php

namespace App\Repositories\Interface;

use App\DTOs\Admin\AdminProfileDto;

interface AdminProfileRepositoryInterface
{
    public function findAdminProfileByPublicId(string $publicId): ?AdminProfileDto;
}