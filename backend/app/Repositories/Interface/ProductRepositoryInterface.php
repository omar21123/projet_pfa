<?php

namespace App\Repositories\Interface;

use App\DTOs\Product\BlockProductDto;
use App\DTOs\Product\CreateProductDto;
use App\DTOs\Product\GetAllProductsAdminDto;
use App\DTOs\Product\PaginatedProductAdminResponseDto;
use App\DTOs\Product\PaginatedProductItemResponseDto;
use App\DTOs\Product\ProductDetailsDto;
use App\DTOs\Product\RefuseProductDto;
use App\DTOs\Product\RefuseProductResultDto;
use App\DTOs\Product\ValidateProductDto;
use App\DTOs\Product\ProductCombinationDetailDto;
use App\DTOs\Product\ProductSearchResultDto;
use App\DTOs\Product\SearchProductsByTermDto;
use App\DTOs\Product\UpdateProductCombinationDto;
use App\DTOs\Product\vendor\GetVendorProductsDto;
use App\DTOs\Product\vendor\PaginatedVendorProductResponseDto;

interface ProductRepositoryInterface
{
    public function create(CreateProductDto $dto): ?object;
    public function getAllProductsAdmin(GetAllProductsAdminDto $dto): PaginatedProductAdminResponseDto;
    public function getProductDetails(int $productId): ProductDetailsDto;
    public function isExistsByID(int $productID): bool;
    public function validate(ValidateProductDto $dto): void;
    public function block(BlockProductDto $dto): void;
    public function refuse(RefuseProductDto $dto): RefuseProductResultDto;
    public function getProductCombinationsForVendor(string $userPublicId, int $productId): array;
    public function searchByTerm(SearchProductsByTermDto $dto): PaginatedProductItemResponseDto;
    public function getCombinationById(string $userPublicId, int $combinationId): ProductCombinationDetailDto;
    public function updateCombination(UpdateProductCombinationDto $dto): ProductCombinationDetailDto;
    public function getProductsForVendor(GetVendorProductsDto $dto): PaginatedVendorProductResponseDto;
    public function searchProductsFullText(string $query, ?string $userPublicId): ProductSearchResultDto;
}
