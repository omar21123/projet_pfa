<?php
// App\Services\StoreRatingService
namespace App\Services;

use App\Repositories\Interface\StoreRatingRepositoryInterface;
use App\Services\Interface\StoreRatingServiceInterface;

class StoreRatingService implements StoreRatingServiceInterface
{
    public function __construct(
        protected StoreRatingRepositoryInterface $storeRatingRepository,
    ) {}

    public function insert(string $userPublicID, int $vendorProfileID, int $rating, ?string $comment): bool
    {
        return $this->storeRatingRepository->insert($userPublicID, $vendorProfileID, $rating, $comment);
    }

    public function update(string $userPublicID, int $vendorProfileID, int $rating, ?string $comment): bool
    {
        return $this->storeRatingRepository->update($userPublicID, $vendorProfileID, $rating, $comment);
    }

    public function delete(string $userPublicID, int $vendorProfileID): bool
    {
        return $this->storeRatingRepository->delete($userPublicID, $vendorProfileID);
    }

    public function getByVendor(int $vendorProfileID, int $pageNumber, int $pageSize): array
    {
        return $this->storeRatingRepository->getByVendor($vendorProfileID, $pageNumber, $pageSize);
    }
}