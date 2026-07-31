<?php

namespace App\Repositories\Interface;

use App\DTOs\Search\SearchSuggestionsQueryDto;
use App\DTOs\Search\SearchSuggestionDto;
use App\DTOs\Search\GetSearchHistoryDto;
use App\DTOs\Search\SearchHistoryItemDto;

interface SearchRepositoryInterface
{
    /** @return SearchSuggestionDto[] */
    public function getSuggestions(SearchSuggestionsQueryDto $dto): array;


    /** @return array{latest: SearchHistoryItemDto[], famous: SearchHistoryItemDto[]} */
    public function getUserSearchHistory(GetSearchHistoryDto $dto, int $userId): array;
}
