<?php

namespace App\Services\Interface;

use App\DTOs\Product\CreateProductDto;

interface ProductServiceInterface
{
    public function createProduct(CreateProductDto $dto): object;
}