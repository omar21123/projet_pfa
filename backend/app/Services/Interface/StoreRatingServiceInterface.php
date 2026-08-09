<?php
// App\Services\Interface\StoreRatingServiceInterface
namespace App\Services\Interface;

interface StoreRatingServiceInterface
{
    public function insert(string $userPublicID, int $vendorProfileID, int $rating, ?string $comment): bool;
    public function update(string $userPublicID, int $vendorProfileID, int $rating, ?string $comment): bool;
    public function delete(string $userPublicID, int $vendorProfileID): bool;
    public function getByVendor(int $vendorProfileID, int $pageNumber, int $pageSize): array;
}