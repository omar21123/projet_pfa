<?php

namespace App\Services;

use App\DTOs\ProductLike\AddProductLikeDto;
use App\DTOs\ProductLike\ProductLikeResultDto;
use App\DTOs\ProductLike\RemoveProductLikeDto;
use App\DTOs\ProductLike\ProductLikeDto;
use App\Services\Interface\ProductLikeServiceInterface;
use App\Repositories\Interface\ProductLikeRepositoryInterface;

class ProductLikeService implements ProductLikeServiceInterface
{
    public function __construct(
        private ProductLikeRepositoryInterface $productLikeRepository,
    ) {}

    public function addLike(AddProductLikeDto $dto): ProductLikeResultDto
    {
        return $this->productLikeRepository->addLike($dto);
    }

    public function removeLike(RemoveProductLikeDto $dto): void
    {
        $this->productLikeRepository->removeLike($dto);
    }

    public function getUserLikes(string $userPublicId): array
    {
        return $this->productLikeRepository->getUserLikes($userPublicId);
    }
}