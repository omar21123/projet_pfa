<?php

namespace App\Services;

use App\DTOs\Admin\AdminProfileDto;
use App\Repositories\Interface\AdminProfileRepositoryInterface;
use App\Services\Interface\AdminProfileServiceInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class AdminProfileService implements AdminProfileServiceInterface
{
    public function __construct(
        protected AdminProfileRepositoryInterface $adminProfileRepository
    ) {}

    public function getAdminProfile(string $publicId): AdminProfileDto
    {
        $profile = $this->adminProfileRepository->findAdminProfileByPublicId($publicId);

        if (!$profile) {
            throw new ModelNotFoundException("Le profil administrateur demandé est introuvable ou inactif.");
        }

        return $profile;
    }
}