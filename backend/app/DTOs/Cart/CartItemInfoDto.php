<?php
// App\DTOs\Cart\CartItemInfoDto
namespace App\DTOs\Cart;

class CartItemInfoDto
{
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
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            cartItemID: isset($row->CartItemID) ? (int) $row->CartItemID : null,
            productId: (int) $row->ProductID,
            combinationId: (int) $row->CombinationID,
            productName: $row->ProductName,
            productDescription: $row->ProductDescription,
            brandName: $row->BrandName,
            modelName: $row->ModelName,
            unitPrice: (float) $row->UnitPrice,
            quantity: (float) $row->Quantity,
            stock: (int) $row->Stock,
            sku: $row->SKU,
            imagePath: $row->ImagePath,
        );
    }
}
