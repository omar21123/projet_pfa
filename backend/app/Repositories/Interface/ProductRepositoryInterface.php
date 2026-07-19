<?php

namespace App\Repositories\Interface;

use App\DTOs\Product\CreateProductDto;
use App\DTOs\Product\GetAllProductsAdminDto;
use App\DTOs\Product\PaginatedProductAdminResponseDto;

interface ProductRepositoryInterface
{
    public function create(CreateProductDto $dto): ?object;
    public function getAllProductsAdmin(GetAllProductsAdminDto $dto): PaginatedProductAdminResponseDto;
}