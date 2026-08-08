<?php
// App\DTOs\Product\ProductRecommendationsGroupedDto
namespace App\DTOs\Product;

class ProductRecommendationsGroupedDto
{
    /**
     * @param array $mostSold  Tableaux déjà passés par ->toArray() (ProductItemDto)
     * @param array $promotions Réservé — pas encore alimenté
     * @param array $trending   Produits tendance
     * 
     */
    public function __construct(
        public readonly array $mostSold,
        public readonly array $mostViewed,
        public readonly array $promotions,
        public readonly array $trending ,
        public readonly array $fromYourLastActivity,
        public readonly array $popularInYourRegion,
        public readonly array $newestproducts
    ) {}

    public function toArray(): array
    {
        return [
            'MostSold'    => $this->mostSold,
            'MostViewed'  => $this->mostViewed,
            'Promotions'  => $this->promotions,
            'Trending'    => $this->trending,
            'FromYourLastActivity' => $this->fromYourLastActivity,
            'PopularInYourRegion' => $this->popularInYourRegion,
            'NewestProducts' => $this->newestproducts
        ];
    }
}