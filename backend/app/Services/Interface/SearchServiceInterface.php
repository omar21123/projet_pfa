<?php

namespace App\Services\Interface;

use App\DTOs\Search\SearchSuggestionsQueryDto;
use App\DTOs\Search\SearchSuggestionDto;

interface SearchServiceInterface
{
    /** @return SearchSuggestionDto[] */
    public function getSuggestions(SearchSuggestionsQueryDto $dto): array;
}