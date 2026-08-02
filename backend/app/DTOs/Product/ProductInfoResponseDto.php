<?php
// App\DTOs\Product\ProductInfoResponseDto
namespace App\DTOs\Product;

class ProductInfoResponseDto
{
    /**
     * @param ProductInfoCategoryDto[] $productCategories
     * @param ProductInfoAllowedPaymentDto[] $productAllowedPayments
     * @param ProductInfoConfigDto[] $productDetails
     * @param ProductInfoCombinationDto[] $productOptionsCombinaison
     * @param ProductInfoTagDto[] $productTags
     */
    public function __construct(
        public readonly string $productName,
        public readonly ?string $productDescription,
        public readonly float $basePrice,
        public readonly ?string $brandName,
        public readonly ?string $modelName,
        public readonly int $stock,
        public readonly int $totalSales,
        public readonly int $totalLiked,
        public readonly int $totalWishlists,
        public readonly array $productCategories,
        public readonly array $productAllowedPayments,
        public readonly array $productDetails,
        public readonly ?string $defaultProductImage,
        public readonly array $productOptionsCombinaison,
        public readonly array $productTags,
    ) {}

    public function toArray(): array
    {
        return [
            'ProductName'                => $this->productName,
            'ProductDescription'         => $this->productDescription,
            'BasePrice'                  => $this->basePrice,
            'BrandName'                  => $this->brandName,
            'ModelName'                  => $this->modelName,
            'Stock'                      => $this->stock,
            'TotalSales'                 => $this->totalSales,
            'TotalLiked'                 => $this->totalLiked,
            'TotalWishlists'             => $this->totalWishlists,
            'ProductCategories'          => array_map(fn($c) => $c->toArray(), $this->productCategories),
            'ProductAllowedPayements'    => array_map(fn($p) => $p->toArray(), $this->productAllowedPayments),
            'ProductDetails'             => array_map(fn($d) => $d->toArray(), $this->productDetails),
            'DefaultProductImage'        => $this->defaultProductImage,
            'ProductOptionsCombiniason'  => array_map(fn($c) => $c->toArray(), $this->productOptionsCombinaison),
            'ProductTags'                => array_map(fn($t) => $t->toArray(), $this->productTags),
        ];
    }
}