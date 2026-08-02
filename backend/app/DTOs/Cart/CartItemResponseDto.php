<?php
// App\DTOs\Cart\CartItemResponseDto
namespace App\DTOs\Cart;

class CartItemResponseDto
{
    /** @param CartItemCombinationDto[] $productOptionsCombinations */
    public function __construct(
        public readonly string $productName,
        public readonly ?string $productDescription,
        public readonly string $brandName,
        public readonly string $modelName,
        public readonly int $stock,
        public readonly ?string $defaultProductImage,
        public readonly array $productOptionsCombinations,
        public readonly bool $hasPromotion,
        public readonly ?CartItemPromotionDto $promotionDetails,
    ) {}

    public function toArray(): array
    {
        return [
            'ProductName'                => $this->productName,
            'ProductDescription'         => $this->productDescription,
            'BrandName'                  => $this->brandName,
            'ModelName'                  => $this->modelName,
            'Stock'                      => $this->stock,
            'DefaultProductImage'        => $this->defaultProductImage,
            'ProductOptionsCombinations' => array_map(fn($c) => $c->toArray(), $this->productOptionsCombinations),
            'HasPromotion'               => $this->hasPromotion,
            'PromotionDetails'           => $this->promotionDetails?->toArray(),
        ];
    }
}