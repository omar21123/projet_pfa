<?php

namespace App\DTOs\Cart;

class CartItemResponseDto
{
    /** @param CombinationDetailInfoDto[] $combinationDetails
     *  @param string[] $defaultImages
     */
    public function __construct(
        public readonly ?int $cartItemID,
        public readonly int $productId,
         
        public readonly int $combinationId,
        public readonly string $productName,
        public readonly ?string $productDescription,
        public readonly string $brandName,
        public readonly string $modelName,
        public readonly float $unitPrice,
        public readonly float $quantity,
        public readonly int $stock,
        public readonly ?string $sku,
        public readonly ?string $imagePath,
        public  array $combinationDetails,
        public  array $defaultImages,
        public  bool $hasPromotion,
        public  ?CartPromotionInfoDto $promotion,
    ) {}
    public static function fromInfoDto(CartItemInfoDto $infoDto): self
    {
        return new self(
            cartItemID : $infoDto->cartItemID,
            productId: $infoDto->productId,
            combinationId: $infoDto->combinationId,
            productName: $infoDto->productName,
            productDescription: $infoDto->productDescription,
            brandName: $infoDto->brandName,
            modelName: $infoDto->modelName,
            unitPrice: $infoDto->unitPrice,
            quantity: $infoDto->quantity,
            stock: $infoDto->stock,
            sku: $infoDto->sku,
            imagePath: $infoDto->imagePath,
            combinationDetails: [],
            defaultImages: [],
            hasPromotion: false,
            promotion: null,
        );
    }
    public function toArray(): array
    {
        return [
            'CartItemID' => $this->cartItemID,
            'ProductID'          => $this->productId,
            'CombinationID'      => $this->combinationId,
            'ProductName'        => $this->productName,
            'ProductDescription' => $this->productDescription,
            'BrandName'          => $this->brandName,
            'ModelName'          => $this->modelName,
            'UnitPrice'          => $this->unitPrice,
            'Quantity'           => $this->quantity,
            'Stock'              => $this->stock,
            'SKU'                => $this->sku,
            'ImagePath'          => $this->imagePath,
            'CombinationDetails' => array_map(fn($d) => $d->toArray(), $this->combinationDetails),
            'DefaultImages'      => $this->defaultImages,
            'HasPromotion'       => $this->hasPromotion,
            'Promotion'          => $this->promotion?->toArray(),
        ];
    }
}
