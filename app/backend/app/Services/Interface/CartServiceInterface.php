<?php

namespace App\Services\Interface;

use App\DTOs\Cart\AddCartItemDto;
use App\DTOs\Cart\CartItemResponseDto;
use App\DTOs\Cart\GetCartDto;
use App\DTOs\Cart\RemoveCartItemDto;
use App\DTOs\Cart\UpdateCartItemQuantityDto;

interface CartServiceInterface
{
    public function addItem(AddCartItemDto $dto): string;
    public function removeItem(RemoveCartItemDto $dto): string;
    /**
     * @return CartItemResponseDto[]
     */
    public function getCart(GetCartDto $dto): array;
    public function updateItemQuantity(UpdateCartItemQuantityDto $dto): string;

}
