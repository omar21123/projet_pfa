<?php
namespace App\Services;

use App\Services\Interface\AdminServiceInterface;
use App\Repositories\Interface\AdminRepositoryInterface;
use App\DTOs\Admin\CreateAdminDto;
use Exception;

class AdminService implements AdminServiceInterface
{
    public function __construct(
        protected AdminRepositoryInterface $adminRepository
    ) {
    }

    public function registerAdmin(CreateAdminDto $dto): object
    {
        $admin = $this->adminRepository->createAdmin($dto);

        if (!$admin) {
            throw new Exception("Impossible de créer le compte administrateur.");
        }

        return $admin;
    }
}