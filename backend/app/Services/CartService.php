<?php

namespace App\Services;

use App\DTOs\Cart\AddCartItemDto;
use App\DTOs\Cart\GetCartDto;
use App\DTOs\Cart\RemoveCartItemDto;
use App\DTOs\Search\RecordSearchClickDto;
use App\Services\Interface\CartServiceInterface;
use App\Repositories\Interface\CartRepositoryInterface;
use App\Repositories\Interface\SearchRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use App\Repositories\Interface\ProductRepositoryInterface;
use App\Services\Interface\ProductServiceInterface;

class CartService implements CartServiceInterface
{
    public function __construct(
        protected CartRepositoryInterface $cartRepository,
        protected SearchRepositoryInterface $searchRepository,
        protected ProductRepositoryInterface $productService
    ) {}

    public function addItem(AddCartItemDto $dto): string
    {
        if ($dto->fromSearch && $dto->searchTerm) {
            try {
                $this->searchRepository->recordSearchClick(
                    new RecordSearchClickDto($dto->searchTerm, $dto->productId)
                );
            } catch (BusinessValidationException $e) {
                // Terme introuvable dans le dictionnaire -> non bloquant pour l'ajout au panier.
            }
        }

        return $this->cartRepository->addItem($dto);
    }
    public function removeItem(RemoveCartItemDto $dto): string
    {
        return $this->cartRepository->removeItem($dto);
    }
    public function getCart(GetCartDto $dto): array
    {
        $productRows = $this->cartRepository->getCartItemsInfo($dto->userPublicId);
        foreach ($productRows as $index => $productRow) {
            $productRows[$index]->defaultImages = $this->productService->getProductImages($productRow->productId);
            $productRows[$index]->combinationDetails = $this->cartRepository->getCombinationDetails($productRow->combinationId);
            $productRows[$index]->hasPromotion = $this->productService->hasActivePromotion($productRow->productId);
            if ($productRows[$index]->hasPromotion) {
                $productRows[$index]->promotion = $this->cartRepository->getCartItemPromotion($productRow->productId);
            } else {
                $productRows[$index]->promotion = null;
            }
        }
        return $productRows;
    }
}
