<?php

namespace App\Services;

use App\DTOs\Product\BlockProductDto;
use App\DTOs\Product\CreateProductDto;
use App\DTOs\Product\GetAllProductsAdminDto;
use App\DTOs\Product\GetProductInfoDto;
use App\DTOs\Product\PaginatedProductAdminResponseDto;
use App\DTOs\Product\PaginatedProductItemResponseDto;
use App\DTOs\Product\ProductCombinationDto;
use App\DTOs\Product\ProductDetailsDto;
use App\DTOs\Product\RefuseProductDto;
use App\DTOs\Product\RefuseProductResultDto;
use App\DTOs\Product\ValidateProductDto;
use App\Services\Interface\ProductServiceInterface;
use App\Repositories\Interface\ProductRepositoryInterface;
use App\DTOs\Product\ProductCombinationDetailDto;
use App\DTOs\Product\ProductInfoResponseDto;
use App\DTOs\Product\ProductSearchResultDto;
use App\DTOs\Product\SearchProductsByTermDto;
use App\DTOs\Product\UpdateProductCombinationDto;
use App\DTOs\Product\vendor\GetVendorProductsDto;
use App\DTOs\Product\vendor\PaginatedVendorProductResponseDto;

class ProductService implements ProductServiceInterface
{
    public function __construct(
        protected ProductRepositoryInterface $productRepository
    ) {}

    public function createProduct(CreateProductDto $dto): object
    {
        return $this->productRepository->create($dto);
    }

    public function getAllProductsAdmin(GetAllProductsAdminDto $dto): PaginatedProductAdminResponseDto
    {
        return $this->productRepository->getAllProductsAdmin($dto);
    }
    public function getProductDetails(int $productId): ProductDetailsDto
    {
        return $this->productRepository->getProductDetails($productId);
    }

    public function isExistsByID(int $productID): bool
    {
        return $this->productRepository->isExistsByID($productID);
    }
    public function validateProduct(ValidateProductDto $dto): void
    {
        $this->productRepository->validate($dto);
    }
    public function blockProduct(BlockProductDto $dto): void
    {
        $this->productRepository->block($dto);
    }
    public function refuseProduct(RefuseProductDto $dto): RefuseProductResultDto
    {
        return $this->productRepository->refuse($dto);
    }

    /**
     * @return ProductCombinationDto[]
     */
    public function getProductCombinationsForVendor(string $userPublicId, int $productId): array
    {
        return $this->productRepository->getProductCombinationsForVendor($userPublicId, $productId);
    }

    public function getCombinationById(string $userPublicId, int $combinationId): ProductCombinationDetailDto
    {
        return $this->productRepository->getCombinationById($userPublicId, $combinationId);
    }

    public function updateCombination(UpdateProductCombinationDto $dto): ProductCombinationDetailDto
    {
        return $this->productRepository->updateCombination($dto);
    }
    public function getProductsForVendor(GetVendorProductsDto $dto): PaginatedVendorProductResponseDto
    {
        return $this->productRepository->getProductsForVendor($dto);
    }
    public function searchByTerm(SearchProductsByTermDto $dto): PaginatedProductItemResponseDto
    {
        return $this->productRepository->searchByTerm($dto);
    }
    public function searchProductsFullText(string $query, ?string $userPublicId): ProductSearchResultDto
    {
        return $this->productRepository->searchProductsFullText($query, $userPublicId);
    }
    public function getProductInfo(GetProductInfoDto $dto): ProductInfoResponseDto
    {
        // TODO: Si $dto->fromSearch est vrai, résoudre le SearchTermID à partir de
        // $dto->searchTerm (lookup simple dans SearchDictionary — pas d'upsert ici,
        // le terme a déjà dû être upserté au moment de la recherche elle-même).

        // TODO: Si un SearchTermID a été résolu ci-dessus, mettre à jour
        // SearchTermProductStats pour la paire (SearchTermID, ProductID) —
        // incrémenter ImpressionCount ou ClickCount selon la sémantique voulue.
        // Nécessite une nouvelle SP dédiée (ex: SP_IncrementSearchTermProductImpression),
        // à ne pas confondre avec SP_InsertSearchTermProductStats (qui ne fait
        // qu'initialiser une ligne à zéro).

        // TODO: Charger les infos de base du produit (nom, description, prix,
        // marque, modèle, stock, image par défaut) — nouvelle SP (ex: SP_GetProductInfo).
        // Doit aussi vérifier que le produit existe et est visible (actif, non bloqué).

        // TODO: Charger les totaux d'engagement (TotalSales, TotalLiked,
        // TotalWishlists) — soit dans la même SP que ci-dessus, soit via des
        // sous-requêtes séparées (cf. patterns déjà utilisés dans SP_SearchProductsByTerm).

        // TODO: Charger les catégories du produit (ProductCategories), avec IsPrimary.

        // TODO: Charger les moyens de paiement autorisés (ProductAllowedPayements),
        // avec code, IconURL, WithdrawTax, IsOnline.

        // TODO: Charger les attributs de configuration + leurs options
        // (ProductDetails) — regrouper par ConfigID/ConfigName.

        // TODO: Charger les combinaisons/variantes (ProductOptionsCombiniason)
        // avec leur config associée. Attention : le schéma de réponse actuel a
        // "Configs" au singulier (un seul objet ConfigID/OptionID par combinaison) —
        // à valider si une combinaison ne porte réellement qu'un seul attribut,
        // ou si la réponse doit plutôt être un tableau de configs par combinaison
        // pour supporter les produits multi-attributs (ex: Couleur + Taille).

        // TODO: Charger les tags du produit (ProductTags).

        // TODO: Assembler tous les éléments ci-dessus dans un ProductInfoResponseDto
        // et le retourner.

        throw new \RuntimeException('getProductInfo() n\'est pas encore implémenté.');
    }
}
