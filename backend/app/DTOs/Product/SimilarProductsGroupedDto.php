<?php
// App\DTOs\Product\SimilarProductsGroupedDto
namespace App\DTOs\Product;

class SimilarProductsGroupedDto
{
    /**
     * @param PublicProductInfoDto[] $similarProducts
     * @param PublicProductInfoDto[] $similarInBrandsOrModels
     * @param PublicProductInfoDto[] $similarInCategories
     */
    public function __construct(
        public readonly array $similarProducts,
        public readonly array $similarInBrandsOrModels,
        public readonly array $similarInCategories,
    ) {}

    public function toArray(): array
    {
        return [
            'SimilarProducts'          => array_map(fn($p) => $p->toArray(), $this->similarProducts),
            'SimilarInBrandsOrModels'  => array_map(fn($p) => $p->toArray(), $this->similarInBrandsOrModels),
            'SimilarInCategories'      => array_map(fn($p) => $p->toArray(), $this->similarInCategories),
        ];
    }
}