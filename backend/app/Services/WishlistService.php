<?php

namespace App\Services;

use App\DTOs\Wishlist\CreateWishlistDto;
use App\DTOs\Wishlist\WishlistDto;
use App\DTOs\Wishlist\AddWishlistItemDto;
use App\DTOs\Wishlist\WishlistItemResultDto;
use App\DTOs\Wishlist\RemoveWishlistItemDto;
use App\DTOs\Wishlist\DeleteWishlistDto;
use App\Services\Interface\WishlistServiceInterface;
use App\Repositories\Interface\WishlistRepositoryInterface;

class WishlistService implements WishlistServiceInterface
{
    public function __construct(
        private WishlistRepositoryInterface $wishlistRepository,
    ) {}

    public function create(CreateWishlistDto $dto): WishlistDto
    {
        return $this->wishlistRepository->create($dto);
    }

    public function addItem(AddWishlistItemDto $dto): WishlistItemResultDto
    {
        return $this->wishlistRepository->addItem($dto);
    }

    public function removeItem(RemoveWishlistItemDto $dto): void
    {
        $this->wishlistRepository->removeItem($dto);
    }

    public function delete(DeleteWishlistDto $dto): void
    {
        $this->wishlistRepository->delete($dto);
    }

    public function getUserWishlists(string $userPublicId): array
    {
        return $this->wishlistRepository->getUserWishlists($userPublicId);
    }
}