<?php

namespace App\Services;

use App\DTOs\Cart\AddCartItemDto;
use App\DTOs\Cart\GetCartDto;
use App\DTOs\Cart\RemoveCartItemDto;
use App\DTOs\Cart\UpdateCartItemQuantityDto;
use App\DTOs\Search\RecordSearchClickDto;
use App\Services\Interface\CartServiceInterface;
use App\Repositories\Interface\CartRepositoryInterface;
use App\Repositories\Interface\SearchRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use App\Repositories\Interface\ProductRepositoryInterface;
use App\Services\Interface\ProductServiceInterface;
use Illuminate\Support\Facades\Log;


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
                $this->cartRepository->addItem($dto);
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
        Log::info("========== GET CART START ==========", [
            'userPublicId' => $dto->userPublicId,
        ]);

        $productRows = $this->cartRepository->getCartItemsInfo($dto->userPublicId);

        Log::info("STEP 1 - Cart items fetched", [
            'userPublicId' => $dto->userPublicId,
            'itemCount'    => count($productRows),
        ]);

        foreach ($productRows as $index => $productRow) {

            Log::info("STEP 2 - Enriching cart item", [
                'index'         => $index,
                'productId'     => $productRow->productId,
                'combinationId' => $productRow->combinationId,
            ]);

            $productRows[$index]->defaultImages = $this->productService->getProductImages($productRow->productId);

            Log::info("Product images loaded", [
                'productId'  => $productRow->productId,
                'imageCount' => count($productRows[$index]->defaultImages),
            ]);

            $productRows[$index]->combinationDetails = $this->cartRepository->getCombinationDetails($productRow->combinationId);

            Log::info("Combination details loaded", [
                'combinationId' => $productRow->combinationId,
                'detailCount'   => count($productRows[$index]->combinationDetails),
            ]);

            $productRows[$index]->hasPromotion = $this->productService->hasActivePromotion($productRow->productId);

            Log::info("Promotion check result", [
                'productId'    => $productRow->productId,
                'hasPromotion' => $productRows[$index]->hasPromotion,
            ]);

            if ($productRows[$index]->hasPromotion) {
                $productRows[$index]->promotion = $this->cartRepository->getCartItemPromotion($productRow->productId);

                Log::info("Promotion details loaded", [
                    'productId' => $productRow->productId,
                    'promotion' => $productRows[$index]->promotion,
                ]);
            } else {
                $productRows[$index]->promotion = null;
            }
        }

        Log::info("========== GET CART SUCCESS ==========", [
            'userPublicId' => $dto->userPublicId,
            'itemCount'    => count($productRows),
        ]);

        return $productRows;
    }
    public function updateItemQuantity(UpdateCartItemQuantityDto $dto): string
    {
        return $this->cartRepository->updateItemQuantity($dto);
    }
}
