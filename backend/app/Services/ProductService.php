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
use App\DTOs\Product\ProductInfoConfigDto;
use App\DTOs\Product\ProductInfoCombinationConfigDto;
use App\DTOs\Product\ProductInfoResponseDto;
use App\DTOs\Product\ProductSearchResultDto;
use App\DTOs\Product\SearchProductsByTermDto;
use App\DTOs\Product\SimilarProductsGroupedDto;
use App\DTOs\Product\Stats\IncrementRegionalProductStatDto;
use App\DTOs\Product\UpdateProductCombinationDto;
use App\DTOs\Product\vendor\GetVendorProductsDto;
use App\DTOs\Product\vendor\PaginatedVendorProductResponseDto;
use App\Repositories\Interface\SearchRepositoryInterface;
use App\DTOs\Search\RecordSearchClickDto;
use App\Repositories\Interface\ProductStatsRepositoryInterface;
use Illuminate\Support\Facades\Log;

class ProductService implements ProductServiceInterface
{
    public function __construct(
        protected ProductRepositoryInterface $productRepository,
        protected SearchRepositoryInterface $searchRepository,
        protected ProductStatsRepositoryInterface $productStatsRepository,
        protected IpWhoIsLocationService $ipWhoIsLocationService
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
        if ($dto->fromSearch && $dto->searchTerm) {
            try {
                $this->searchRepository->recordSearchClick(
                    new RecordSearchClickDto($dto->searchTerm, $dto->productId)
                );
            } catch (\App\Exceptions\BusinessValidationException $e) {
                // Terme introuvable dans le dictionnaire (ex: SearchTerm invalide/périmé) ->
                // non bloquant pour l'affichage du produit, on ignore simplement.
            }
        }

        $productbasicInfos = $this->productRepository->getPublicProductInfo($dto->productId);
        if (!$productbasicInfos) {
            throw new \App\Exceptions\BusinessValidationException(
                'Product not found or not visible to the public.',
                404
            );
        }
        $categories = $this->productRepository->getProductCategories($dto->productId);
        $allowedPayments = $this->productRepository->getProductAllowedPayments($dto->productId);
        $productDetails = [];
        foreach ($this->productRepository->getProductConfigs($dto->productId) as $detail) {
            $options = $this->productRepository->getProductConfigOptions($dto->productId, $detail->configId);
            $productDetails[] = new ProductInfoConfigDto(
                configId: $detail->configId,
                configName: $detail->configName,
                options: $options,
            );
        }
        $images = $this->productRepository->getProductImages($dto->productId);
        $productOptionsCombinaison = $this->productRepository->getProductCombinations($dto->productId);
        foreach ($productOptionsCombinaison as $combination) {
            $combinationConfig = $this->productRepository->getCombinationConfigs($combination->combinationId);
            $combination->configs = $combinationConfig;
        }
        $productTags = $this->productRepository->getProductTags($dto->productId);
        $hasPromotion = $this->productRepository->hasActivePromotion($dto->productId);
        if ($hasPromotion) {
            $productPromotion = $this->productRepository->getProductPromotion($dto->productId);
        } else {
            $productPromotion = null;
        }
        $Region = $this->ipWhoIsLocationService->locate($dto->ipAddress);
        $productStatDto = IncrementRegionalProductStatDto::fromArray([
            'ProductID'   => $dto->productId,
            'CountryCode' => $Region?->countryCode ?? null,
            'Region'      => $Region?->region ?? null,
        ]);
        Log::info('Incrementing product view count for Ip: ' . $dto->ipAddress . ', Product ID: ' . $dto->productId . ', Country: ' . ($Region?->countryCode ?? 'N/A') . ', Region: ' . ($Region?->region ?? 'N/A'));
        $this->productStatsRepository->incrementViewCount($productStatDto);
        return new ProductInfoResponseDto(
            productName: $productbasicInfos->productName,
            productDescription: $productbasicInfos->productDesc,
            productID: $productbasicInfos->productId,
            basePrice: $productbasicInfos->basePrice,
            brandID: $productbasicInfos->brandId,
            brandName: $productbasicInfos->brandName,
            modelName: $productbasicInfos->modelName,
            stock: $productbasicInfos->stock,
            totalSales: $productbasicInfos->totalOrders,
            totalLiked: $productbasicInfos->totalLikes,
            totalWishlists: $productbasicInfos->totalWishlists,
            productCategories: $categories,
            productAllowedPayments: $allowedPayments,
            productDetails: $productDetails,
            defaultProductImage: $images ? array_slice($images, 0, 1) : null,
            productOptionsCombinaison: $productOptionsCombinaison,
            productTags: $productTags,
            HasPromotion: $hasPromotion,
            productPromotion: $productPromotion,
        );
    }
    public function getSimilarProducts(int $productId, int $limit = 10): SimilarProductsGroupedDto
    {
        $similarProducts = $this->productRepository->getSimilarProducts($productId, $limit);
        $similarinBrandsOrModels = $this->productRepository->getSimilarProductsByBrandOrModel($productId, $limit);
        $similarinCategories = $this->productRepository->getSimilarProductsByCategory($productId, $limit);
        return new SimilarProductsGroupedDto(
            similarProducts: $similarProducts,
            similarInBrandsOrModels: $similarinBrandsOrModels,
            similarInCategories: $similarinCategories
        );
    }
}
