<?php

namespace App\Services\Interface;

use App\DTOs\Admin\AdminProfileDto;

interface AdminProfileServiceInterface
{
    public function getAdminProfile(string $publicId): AdminProfileDto;
}