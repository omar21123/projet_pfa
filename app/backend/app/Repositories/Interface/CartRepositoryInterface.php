<?php

namespace App\Repositories\Interface;

use App\DTOs\Cart\AddCartItemDto;
use App\DTOs\Cart\RemoveCartItemDto;
use App\DTOs\Cart\CartItemInfoDto;
use App\DTOs\Cart\CartItemResponseDto;
use App\DTOs\Cart\CartPromotionInfoDto;
use App\DTOs\Cart\CombinationDetailInfoDto;
use App\DTOs\Cart\UpdateCartItemQuantityDto;

interface CartRepositoryInterface
{
    public function addItem(AddCartItemDto $dto): string;
    public function removeItem(RemoveCartItemDto $dto): string;
    public function updateItemQuantity(UpdateCartItemQuantityDto $dto): string;

    /** @return CartItemResponseDto[] */
    public function getCartItemsInfo(string $userPublicId): array;

    public function getCartItemPromotion(int $productId): ?CartPromotionInfoDto;

    /** @return CombinationDetailInfoDto[] */
    public function getCombinationDetails(int $combinationId): array;
}
