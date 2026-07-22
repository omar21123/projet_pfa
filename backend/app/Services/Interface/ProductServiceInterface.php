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

interface ProductServiceInterface
{
    public function createProduct(CreateProductDto $dto): object;
    public function getAllProductsAdmin(GetAllProductsAdminDto $dto): PaginatedProductAdminResponseDto;
    public function getProductDetails(int $productId): ProductDetailsDto;
    public function isExistsByID(int $productID): bool;
    public function validateProduct(ValidateProductDto $dto): void;
    public function blockProduct(BlockProductDto $dto): void;
    public function refuseProduct(RefuseProductDto $dto): RefuseProductResultDto;
}