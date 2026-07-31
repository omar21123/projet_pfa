<?php

namespace App\Services;

use App\DTOs\Search\GetSearchHistoryDto;
use App\DTOs\Search\SearchSuggestionsQueryDto;
use App\Services\Interface\SearchServiceInterface;
use App\Repositories\Interface\SearchRepositoryInterface;

class SearchService implements SearchServiceInterface
{
    public function __construct(
        private SearchRepositoryInterface $searchRepository,
    ) {}

    public function getSuggestions(SearchSuggestionsQueryDto $dto): array
    {
        return $this->searchRepository->getSuggestions($dto);
    }
    public function getUserSearchHistory(GetSearchHistoryDto $dto, int $userId): array
{
    return $this->searchRepository->getUserSearchHistory($dto, $userId);
}
}