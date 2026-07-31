<?php

namespace App\Services;

use App\DTOs\Product\ProductSearchITemScrorredDto;
use App\DTOs\Search\GetSearchHistoryDto;
use App\DTOs\Search\SearchSuggestionsQueryDto;
use App\DTOs\Product\SearchProductsByTermDto;
use App\DTOs\Search\InsertSearchTermProductStatsDto;
use App\DTOs\Search\UpsertSearchTermDto;
use App\Helpers\Search\TextComboGenerator;
use App\Services\Interface\SearchServiceInterface;
use App\Repositories\Interface\SearchRepositoryInterface;
use App\Repositories\Interface\ProductRepositoryInterface;
use App\Helpers\Search\TextCombo;
use PhpParser\Node\Expr\List_;

class SearchService implements SearchServiceInterface
{
    public function __construct(
        private SearchRepositoryInterface $searchRepository,
        private ProductRepositoryInterface $productRepository,
    ) {}

    public function getSuggestions(SearchSuggestionsQueryDto $dto): array
    {
        return $this->searchRepository->getSuggestions($dto);
    }

    public function getUserSearchHistory(GetSearchHistoryDto $dto, int $userId): array
    {
        return $this->searchRepository->getUserSearchHistory($dto, $userId);
    }
    public function search(string $query, ?string $userPublicId, int $page, int $pageSize): array
    {
        $globalOffset = ($page - 1) * $pageSize;

        // 1) Recherche directe (source primaire) sur la page demandée.
        $productResult = $this->productRepository->searchByTerm(
            SearchProductsByTermDto::fromArray([
                'Query'        => $query,
                'UserPublicID' => $userPublicId,
                'PageNumber'   => $page,
                'PageSize'     => $pageSize,
            ])
        );

        $firstTotal = $productResult->total;
        $firstItems = $productResult->items;
        $firstCount = count($firstItems);
        $needed     = $pageSize - $firstCount;

        // Cas 1 : la page demandée est entièrement couverte par la source primaire.
        if ($needed <= 0) {
            return [
                'source'   => 'products',
                'items'    => $firstItems,
                'page'     => $page,
                'pageSize' => $pageSize,
                'total'    => $firstTotal, // à concaténer avec le total secondaire si nécessaire (voir note)
                'hasMore'  => ($globalOffset + $firstCount) < $firstTotal,
            ];
        }

        // Cas 2 (mixte) ou Cas 3 (tout secondaire) : il manque $needed lignes.
        // Offset dans la source secondaire = nb de lignes globales déjà "consommées" par la source primaire.
        $secondOffset = max(0, $globalOffset - $firstTotal);

        $combos = TextComboGenerator::getAllCombinations($query);

        $newResultSearch = [];

        foreach ($combos as $combo) {
            $items = $this->productRepository->searchProductsFullText($combo->text, $userPublicId)->items;
            array_push($newResultSearch, new ProductSearchITemScrorredDto(
                items: $items,
                score: $combo->score,
            ));
        }

        $newResultSearch = collect($newResultSearch)
            ->sortByDesc(fn(ProductSearchITemScrorredDto $item) => $item->score)
            ->values()
            ->all();

        // On aplatit tous les items de tous les combos (triés par score) en une seule liste.
        $totalFoundItems = [];
        foreach ($newResultSearch as $result) {
            array_push($totalFoundItems, ...$result->items);
        }

        $secondTotal = count($totalFoundItems);

        // Pagination en mémoire sur la liste aplatie, en utilisant le même offset/needed
        // que pour une source distante.
        $secondItems = array_slice($totalFoundItems, $secondOffset, $needed);

        $items = array_merge($firstItems, $secondItems);
        $total = $firstTotal + $secondTotal; // toujours concaténé
        $upsetResult =  $this->searchRepository->recordSearchTerm(
            UpsertSearchTermDto::fromArray([
                'displayText' => $query,
                'sourceType'  => 1, // 1 = recherche manuelle utilisateur — à aligner avec vos autres valeurs SourceType (ex: 2 = suggestion cliquée, 3 = import catalogue, etc.)
                'sourceId'    => null,
                'resultCount' => $total,
            ])
        );
        $termID = $upsetResult->searchTermId;

        foreach ($totalFoundItems as $item) {
            $this->searchRepository->recordSearchTermProductStats(
                InsertSearchTermProductStatsDto::fromArray([
                    'searchTermId' => $termID,
                    'productId'    => $item->productId,
                ])
            );
        }
        return [
            'items'    => $items,
            'page'     => $page,
            'pageSize' => $pageSize,
            'total'    => $total,
            'hasMore'  => ($globalOffset + count($items)) < $total,
        ];
    }
}
