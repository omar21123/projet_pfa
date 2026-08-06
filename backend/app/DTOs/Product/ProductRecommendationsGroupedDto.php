<?php
// App\DTOs\Product\ProductRecommendationsGroupedDto
namespace App\DTOs\Product;

class ProductRecommendationsGroupedDto
{
    /**
     * @param array $mostSold  Tableaux déjà passés par ->toArray() (ProductItemDto)
     * @param array $promotions Réservé — pas encore alimenté
     */
    public function __construct(
        public readonly array $mostSold,
        public readonly array $mostViewed,
        public readonly array $promotions,
    ) {}

    public function toArray(): array
    {
        return [
            'MostSold'    => $this->mostSold,
            'MostViewed'  => $this->mostViewed,
            'Promotions'  => $this->promotions,
        ];
    }
}