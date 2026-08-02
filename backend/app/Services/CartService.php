<?php

namespace App\Services;

use App\DTOs\Cart\AddCartItemDto;
use App\DTOs\Search\RecordSearchClickDto;
use App\Services\Interface\CartServiceInterface;
use App\Repositories\Interface\CartRepositoryInterface;
use App\Repositories\Interface\SearchRepositoryInterface;
use App\Exceptions\BusinessValidationException;

class CartService implements CartServiceInterface
{
    public function __construct(
        protected CartRepositoryInterface $cartRepository,
        protected SearchRepositoryInterface $searchRepository,
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
}