<?php

namespace App\Services\Interface;

use App\DTOs\Wishlist\CreateWishlistDto;
use App\DTOs\Wishlist\WishlistDto;
use App\DTOs\Wishlist\AddWishlistItemDto;
use App\DTOs\Wishlist\WishlistItemResultDto;
use App\DTOs\Wishlist\RemoveWishlistItemDto;
use App\DTOs\Wishlist\DeleteWishlistDto;

interface WishlistServiceInterface
{
    public function create(CreateWishlistDto $dto): WishlistDto;
    public function addItem(AddWishlistItemDto $dto): WishlistItemResultDto;
    public function removeItem(RemoveWishlistItemDto $dto): void;
    public function delete(DeleteWishlistDto $dto): void;

    /** @return WishlistDto[] */
    public function getUserWishlists(string $userPublicId): array;
}