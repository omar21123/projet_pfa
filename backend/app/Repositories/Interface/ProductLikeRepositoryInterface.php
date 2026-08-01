<?php

namespace App\Repositories\Interface;

use App\DTOs\ProductLike\AddProductLikeDto;
use App\DTOs\ProductLike\ProductLikeResultDto;
use App\DTOs\ProductLike\RemoveProductLikeDto;
use App\DTOs\ProductLike\ProductLikeDto;

interface ProductLikeRepositoryInterface
{
    public function addLike(AddProductLikeDto $dto): ProductLikeResultDto;
    public function removeLike(RemoveProductLikeDto $dto): void;

    /** @return ProductLikeDto[] */
    public function getUserLikes(string $userPublicId): array;
}