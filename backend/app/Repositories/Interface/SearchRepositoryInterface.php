<?php

namespace App\Repositories\Interface;

use App\DTOs\Search\SearchSuggestionsQueryDto;
use App\DTOs\Search\SearchSuggestionDto;

interface SearchRepositoryInterface
{
    /** @return SearchSuggestionDto[] */
    public function getSuggestions(SearchSuggestionsQueryDto $dto): array;
}