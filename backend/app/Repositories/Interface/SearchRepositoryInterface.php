<?php

namespace App\Repositories\Interface;

use App\DTOs\Search\SearchSuggestionsQueryDto;
use App\DTOs\Search\SearchSuggestionDto;
use App\DTOs\Search\GetSearchHistoryDto;
use App\DTOs\Search\InsertSearchTermProductStatsDto;
use App\DTOs\Search\LogUserSearchDto;
use App\DTOs\Search\SearchHistoryItemDto;
use App\DTOs\Search\SearchTermUpsertResultDto;
use App\DTOs\Search\UpdateSearchTermResultCountDto;
use App\DTOs\Search\UpsertSearchTermDto;

interface SearchRepositoryInterface
{
    /** @return SearchSuggestionDto[] */
    public function getSuggestions(SearchSuggestionsQueryDto $dto): array;
    /** @return array{latest: SearchHistoryItemDto[], famous: SearchHistoryItemDto[]} */
    public function getUserSearchHistory(GetSearchHistoryDto $dto, int $userId): array;
    public function recordSearchTerm(UpsertSearchTermDto $dto): SearchTermUpsertResultDto;
    public function recordSearchTermProductStats(InsertSearchTermProductStatsDto $dto): ?int;
    public function logUserSearch(LogUserSearchDto $dto): void;
    // SearchRepositoryInterface — ajouter :
    public function updateSearchTermResultCount(UpdateSearchTermResultCountDto $dto): void;
}
