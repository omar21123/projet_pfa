<?php

namespace App\Repositories\Interface;

use App\DTOs\Product\BlockProductDto;
use App\DTOs\Product\CreateProductDto;
use App\DTOs\Product\GetAllProductsAdminDto;
use App\DTOs\Product\PaginatedProductAdminResponseDto;
use App\DTOs\Product\ProductDetailsDto;
use App\DTOs\Product\RefuseProductDto;
use App\DTOs\Product\RefuseProductResultDto;
use App\DTOs\Product\ValidateProductDto;

interface ProductRepositoryInterface
{
    public function create(CreateProductDto $dto): ?object;
    public function getAllProductsAdmin(GetAllProductsAdminDto $dto): PaginatedProductAdminResponseDto;
    public function getProductDetails(int $productId): ProductDetailsDto;
    public function isExistsByID(int $productID): bool;
    public function validate(ValidateProductDto $dto): void;
    public function block(BlockProductDto $dto): void;
    public function refuse(RefuseProductDto $dto): RefuseProductResultDto;
}