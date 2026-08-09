<?php
// App\Repositories\Interface\StoreRatingRepositoryInterface
namespace App\Repositories\Interface;

use App\DTOs\Vendor\StoreRatingDto;

interface StoreRatingRepositoryInterface
{
    public function insert(string $userPublicID, int $vendorProfileID, int $rating, ?string $comment): bool;
    public function update(string $userPublicID, int $vendorProfileID, int $rating, ?string $comment): bool;
    public function delete(string $userPublicID, int $vendorProfileID): bool;
    public function getByVendor(int $vendorProfileID, int $pageNumber, int $pageSize): array;
}