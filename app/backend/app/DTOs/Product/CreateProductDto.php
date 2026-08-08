<?php

namespace App\DTOs\Product;

use App\DTOs\ProductResource\CreateProductResourceDto;
use App\DTOs\Product\CreateProductAttributeDto;
use App\DTOs\Product\CreateProductCombinationDto;

class CreateProductDto
{
    /** @var CreateProductResourceDto[] */
    public readonly array $resources;
    /** @var int[] */
    public readonly array $categories;
    /** @var CreateProductAttributeDto[] */
    public readonly array $attributes;
    /** @var CreateProductCombinationDto[] */
    public readonly array $combinations;
    /** @var string[] */
    public readonly array $tags;
    /** @var int[] */
    public readonly array $allowedPayment;

    public function __construct(
        public readonly int $vendorID,
        public readonly int $brandID,
        public readonly int $modelID,
        public readonly string $name,
        public readonly string $barcode,
        public readonly ?string $description,
        public readonly float $basePrice,
        public readonly int $stock,
        array $resources = [],
        array $categories = [],
        array $attributes = [],
        array $combinations = [],
        array $tags = [],
        array $allowedPayment = [],
    ) {
        $this->resources = $resources;
        $this->categories = $categories;
        $this->attributes = $attributes;
        $this->combinations = $combinations;
        $this->tags = $tags;
        $this->allowedPayment = $allowedPayment;
    }

    public static function fromArray(array $data): self
    {
        $resources = array_map(fn(array $r) => CreateProductResourceDto::fromArray($r), $data['Ressource'] ?? []);
        $attributes = array_map(fn(array $a) => CreateProductAttributeDto::fromArray($a), $data['Attribute'] ?? []);
        $combinations = array_map(fn(array $c) => CreateProductCombinationDto::fromArray($c), $data['Combinations'] ?? []);

        return new self(
            vendorID: (int) $data['VendorID'],
            brandID: (int) $data['BrandID'],
            modelID: (int) $data['ModelID'],
            name: $data['Name'],
            barcode: $data['Barcode'],
            description: $data['Description'] ?? null,
            basePrice: (float) $data['BasePrice'],
            stock: (int) $data['Stock'],
            resources: $resources,
            categories: array_map('intval', $data['Categories'] ?? []),
            attributes: $attributes,
            combinations: $combinations,
            tags: $data['Tags'] ?? [],
            allowedPayment: array_map('intval', $data['AllowedPayment'] ?? []),
        );
    }
}