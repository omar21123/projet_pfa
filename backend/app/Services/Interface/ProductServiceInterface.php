<?php

namespace App\Services\Interface;

use App\DTOs\Product\BlockProductDto;
use App\DTOs\Product\CreateProductDto;
use App\DTOs\Product\GetAllProductsAdminDto;
use App\DTOs\Product\PaginatedProductAdminResponseDto;
use App\DTOs\Product\ProductDetailsDto;
use App\DTOs\Product\RefuseProductDto;
use App\DTOs\Product\RefuseProductResultDto;
use App\DTOs\Product\ValidateProductDto;
use App\DTOs\Product\ProductCombinationDto;
use App\DTOs\Product\ProductCombinationDetailDto;
use App\DTOs\Product\UpdateProductCombinationDto;
use App\DTOs\Product\vendor\PaginatedVendorProductResponseDto;
use App\DTOs\Product\vendor\GetVendorProductsDto;
use App\DTOs\Product\SearchProductsByTermDto;
use App\DTOs\Product\PaginatedProductItemResponseDto;
use App\DTOs\Product\ProductSearchResultDto;

interface ProductServiceInterface
{
    public function createProduct(CreateProductDto $dto): object;
    public function getAllProductsAdmin(GetAllProductsAdminDto $dto): PaginatedProductAdminResponseDto;
    public function getProductDetails(int $productId): ProductDetailsDto;
    public function isExistsByID(int $productID): bool;
    public function validateProduct(ValidateProductDto $dto): void;
    public function blockProduct(BlockProductDto $dto): void;
    public function refuseProduct(RefuseProductDto $dto): RefuseProductResultDto;
    // ... dans l'interface, à côté des autres méthodes
    /**
     * @return ProductCombinationDto[]
     */
    public function getProductCombinationsForVendor(string $userPublicId, int $productId): array;
    public function searchByTerm(SearchProductsByTermDto $dto): PaginatedProductItemResponseDto;
    public function getCombinationById(string $userPublicId, int $combinationId): ProductCombinationDetailDto;
    public function updateCombination(UpdateProductCombinationDto $dto): ProductCombinationDetailDto;
    public function getProductsForVendor(GetVendorProductsDto $dto): PaginatedVendorProductResponseDto;
    public function searchProductsFullText(string $query, ?string $userPublicId): ProductSearchResultDto;

}
