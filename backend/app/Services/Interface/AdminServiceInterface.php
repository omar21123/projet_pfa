<?php
namespace App\Services\Interface;

use App\DTOs\Admin\CreateAdminDto;

interface AdminServiceInterface
{
    public function registerAdmin(CreateAdminDto $dto): object;
}