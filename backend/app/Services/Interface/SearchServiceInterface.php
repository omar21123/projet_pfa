<?php

namespace App\Services\Interface;

use App\DTOs\Search\SearchSuggestionsQueryDto;
use App\DTOs\Search\SearchSuggestionDto;
use App\DTOs\Search\GetSearchHistoryDto;
use App\DTOs\Search\SearchHistoryItemDto;
use App\Helpers\Search\TextCombo;

interface SearchServiceInterface
{
    /** @return SearchSuggestionDto[] */
    public function getSuggestions(SearchSuggestionsQueryDto $dto): array;

    /** @return array{latest: SearchHistoryItemDto[], famous: SearchHistoryItemDto[]} */
    public function getUserSearchHistory(GetSearchHistoryDto $dto, int $userId): array;

    // app/Services/Interface/SearchServiceInterface.php

    /** @return array{items: TextCombo[], page: int, pageSize: int, total: int, hasMore: bool} */
    public function search(string $query, ?string $userPublicId,?string $IpAddress, int $page, int $pageSize): array;
}
