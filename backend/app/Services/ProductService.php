<?php

namespace App\Services;

use App\DTOs\Product\BlockProductDto;
use App\DTOs\Product\CreateProductDto;
use App\DTOs\Product\GetAllProductsAdminDto;
use App\DTOs\Product\PaginatedProductAdminResponseDto;
use App\DTOs\Product\ProductCombinationDto;
use App\DTOs\Product\ProductDetailsDto;
use App\DTOs\Product\RefuseProductDto;
use App\DTOs\Product\RefuseProductResultDto;
use App\DTOs\Product\ValidateProductDto;
use App\Services\Interface\ProductServiceInterface;
use App\Repositories\Interface\ProductRepositoryInterface;
use App\DTOs\Product\ProductCombinationDetailDto;
use App\DTOs\Product\UpdateProductCombinationDto;
use App\DTOs\Product\vendor\GetVendorProductsDto;
use App\DTOs\Product\vendor\PaginatedVendorProductResponseDto;

class ProductService implements ProductServiceInterface
{
    public function __construct(
        protected ProductRepositoryInterface $productRepository
    ) {
    }

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
}
