<?php
namespace App\Services;

use App\Services\Interface\AdminServiceInterface;
use App\Repositories\Interface\AdminRepositoryInterface;
use App\DTOs\Admin\CreateAdminDto;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Exception;

class AdminService implements AdminServiceInterface
{
    public function __construct(
        protected AdminRepositoryInterface $adminRepository
    ) {
    }

   public function registerAdmin(CreateAdminDto $dto, string $tokenHash, ?string $ipAddress, int $ttl): string
{
    $passwordHash = Hash::make($dto->password);

    $publicId = $this->adminRepository->createAdminUser(
        $dto,
        $passwordHash,
        $tokenHash,
        $ipAddress,
        $ttl
    );

    if (!$publicId) {
        throw new \Exception("Impossible de créer le compte administrateur.");
    }

    return $publicId;
}
}