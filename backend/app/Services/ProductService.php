<?php

namespace App\Services;

use App\DTOs\Product\CreateProductDto;
use App\DTOs\Product\GetAllProductsAdminDto;
use App\DTOs\Product\PaginatedProductAdminResponseDto;
use App\DTOs\Product\ProductDetailsDto;
use App\DTOs\Product\ValidateProductDto;
use App\Services\Interface\ProductServiceInterface;
use App\Repositories\Interface\ProductRepositoryInterface;

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
}
