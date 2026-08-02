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
            'resultCount' => $firstTotal, // nombre réel de résultats, pas la taille de page
        ])
    );
    $termID = $upsetResult->searchTermId;

    // Log uniquement si l'utilisateur est connecté (UserID NOT NULL en base).
    // Les recherches invitées ne sont pas historisées.
    if ($userPublicId !== null) {
        $this->searchRepository->logUserSearch(
            LogUserSearchDto::fromArray([
                'userPublicId' => $userPublicId,
                'searchTermId' => $termID,
                'ipAddress'    => $IpAddress,
            ])
        );
    }

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

    $secondTotal = count($totalFoundItems);
    $secondItems = array_slice($totalFoundItems, $secondOffset, $needed);

    $items = array_merge($firstItems, $secondItems);
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
}
