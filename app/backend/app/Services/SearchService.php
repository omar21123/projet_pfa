<?php

namespace App\Services;

use App\DTOs\Product\ProductSearchITemScrorredDto;
use App\DTOs\Search\GetSearchHistoryDto;
use App\DTOs\Search\SearchSuggestionsQueryDto;
use App\DTOs\Product\SearchProductsByTermDto;
use App\DTOs\Search\InsertSearchTermProductStatsDto;
use App\DTOs\Search\LogUserSearchDto;
use App\DTOs\Search\UpdateSearchTermResultCountDto;
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
    public function search(string $query, ?string $userPublicId, ?string $IpAddress, int $page, int $pageSize): array
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

        // Upsert + log une seule fois par requête, quel que soit le chemin emprunté ensuite.
        $upsetResult = $this->searchRepository->recordSearchTerm(
            UpsertSearchTermDto::fromArray([
                'displayText' => $query,
                'sourceType'  => 1,
                'sourceId'    => null,
                'resultCount' => $firstTotal,
            ])
        );
        $termID = $upsetResult->searchTermId;
        $this->searchRepository->logUserSearch(
            LogUserSearchDto::fromArray([
                'userPublicId' => $userPublicId,
                'searchTermId' => $termID,
                'ipAddress'    => $IpAddress,
            ])
        );

        // Cas 1 : la page demandée est entièrement couverte par la source primaire.
        if ($needed <= 0) {
            return [
                'source'   => 'products',
                'items'    => $firstItems,
                'page'     => $page,
                'pageSize' => $pageSize,
                'total'    => $firstTotal,
                'hasMore'  => ($globalOffset + $firstCount) < $firstTotal,
            ];
        }

        // Cas 2 (mixte) ou Cas 3 (tout secondaire) : il manque $needed lignes.
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

        $totalFoundItems = [];
        foreach ($newResultSearch as $result) {
            array_push($totalFoundItems, ...$result->items);
        }

        // Plusieurs combos peuvent retrouver le même produit — on ne garde
        // que la première occurrence (celle du combo au score le plus élevé,
        // puisque $newResultSearch est déjà trié par score décroissant).
        $totalFoundItems = $this->dedupeByProductId($totalFoundItems);

        $secondTotal = count($totalFoundItems);
        $secondItems = array_slice($totalFoundItems, $secondOffset, $needed);

        // Un produit déjà renvoyé par la recherche primaire peut aussi être
        // retrouvé par le full-text — on déduplique le merge final, en gardant
        // la version de $firstItems en priorité (recherche primaire = source
        // de vérité pour ce produit, notamment IsLiked/IsWishedList à jour).
        $items = $this->dedupeByProductId(array_merge($firstItems, $secondItems));

        $total = $firstTotal + $secondTotal;

        $this->searchRepository->updateSearchTermResultCount(
            UpdateSearchTermResultCountDto::fromArray([
                'searchTermId' => $termID,
                'resultCount'  => $total,
            ])
        );
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

    /**
     * Déduplique une liste de ProductItemDto par productId, en gardant
     * la première occurrence rencontrée. array_values() réindexe le
     * tableau après filtrage pour éviter des clés numériques trouées.
     *
     * @param \App\DTOs\Product\ProductItemDto[] $items
     * @return \App\DTOs\Product\ProductItemDto[]
     */
    private function dedupeByProductId(array $items): array
    {
        $seen = [];

        return array_values(array_filter($items, function ($item) use (&$seen) {
            if (isset($seen[$item->productId])) {
                return false;
            }
            $seen[$item->productId] = true;
            return true;
        }));
    }
}
