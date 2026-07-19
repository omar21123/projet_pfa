<?php

namespace App\Services\Interface;

use App\DTOs\Product\CreateProductDto;
use App\DTOs\Product\GetAllProductsAdminDto;
use App\DTOs\Product\PaginatedProductAdminResponseDto;

interface ProductServiceInterface
{
    public function createProduct(CreateProductDto $dto): object;

    public function getAllProductsAdmin(GetAllProductsAdminDto $dto): PaginatedProductAdminResponseDto;
}