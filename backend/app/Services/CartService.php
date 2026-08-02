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
    public function removeItem(RemoveCartItemDto $dto): string
    {
        return $this->cartRepository->removeItem($dto);
    }
    public function getCart(GetCartDto $dto): array
{
    // TODO: Charger les lignes du panier de l'utilisateur (CartItems via Carts.UserID)
    // — nouvelle SP/méthode repo (ex: CartRepository::getCartItems()).

    // TODO: Pour chaque ligne, charger les infos produit de base (nom, description,
    // marque, modèle, stock, image par défaut) — probablement réutilisable via
    // ProductRepository::getPublicProductInfo() ou une variante allégée dédiée au panier.

    // TODO: Pour chaque ligne, charger la/les combinaison(s) associées
    // (ProductOptionsCombinations) avec leur config/option — attention, le JSON
    // exemple a une seule paire ConfigurationName/ConfingOptionName par combinaison,
    // même ambiguïté singulier/tableau que pour getProductInfo() à trancher.

    // TODO: Pour chaque produit, vérifier s'il a une promotion active
    // (réutiliser ProductRepository::hasActivePromotion() / getProductPromotion()),
    // et mapper vers CartItemPromotionDto (attention: DiscountPercentage n'existe
    // pas tel quel dans Promotions — à dériver de DiscountValue/DiscountTypeID,
    // ou clarifier si seul le type "pourcentage" doit être supporté ici).

    // TODO: Assembler chaque ligne en CartItemResponseDto et retourner le tableau.

    return [];
}
}
