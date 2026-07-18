<?php

namespace App\Repositories\Interface;

use App\DTOs\Product\CreateProductDto;

interface ProductRepositoryInterface
{
    public function create(CreateProductDto $dto): ?object;
}