<?php

namespace App\Services;

use App\DTOs\Product\CreateProductDto;
use App\Services\Interface\ProductServiceInterface;
use App\Repositories\Interface\ProductRepositoryInterface;

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
}