<?php

namespace App\Services\Interface;

use App\DTOs\Search\SearchSuggestionsQueryDto;
use App\DTOs\Search\SearchSuggestionDto;
use App\DTOs\Search\GetSearchHistoryDto;

interface SearchServiceInterface
{
    /** @return SearchSuggestionDto[] */
    public function getSuggestions(SearchSuggestionsQueryDto $dto): array;

    /** @return array{latest: SearchHistoryItemDto[], famous: SearchHistoryItemDto[]} */
    public function getUserSearchHistory(GetSearchHistoryDto $dto, int $userId): array;
}
