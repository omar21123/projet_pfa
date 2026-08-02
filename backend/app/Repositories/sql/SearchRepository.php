<?php

namespace App\Repositories\sql;

use App\DTOs\Search\SearchSuggestionsQueryDto;
use App\DTOs\Search\SearchSuggestionDto;
use App\DTOs\Search\UpsertSearchTermDto;
use App\DTOs\Search\SearchTermUpsertResultDto;
use App\DTOs\Search\InsertSearchTermProductStatsDto;
use App\Repositories\Interface\SearchRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;
use App\DTOs\Search\GetSearchHistoryDto;
use App\DTOs\Search\LogUserSearchDto;
use App\DTOs\Search\SearchHistoryItemDto;
use App\DTOs\Search\UpdateSearchTermResultCountDto;
use App\DTOs\Search\RecordSearchClickDto;

class SearchRepository implements SearchRepositoryInterface
{
    public function getSuggestions(SearchSuggestionsQueryDto $dto): array
    {
        // TODO(Redis): point de cache ici, avant d'appeler la base.
        // Clé suggérée : "search:suggest:{$dto->normalizedQuery}:{$dto->limit}"
        // - cache HIT  -> retourner directement le tableau décodé, skip la SP.
        // - cache MISS -> exécuter la requête ci-dessous, puis SETEX la clé
        //   (TTL court, ex: 300-900s) avec le résultat encodé en JSON.
        // Attention : incrémenter SearchHitCount / SearchHitCount7d ailleurs
        // (ex: au moment où l'utilisateur clique un résultat / lance la recherche
        // réelle) ne doit PAS passer par ce cache, sinon les compteurs ne bougent
        // jamais et le classement se fige.

        $rows = DB::select('CALL SP_GetSearchSuggestions(?, ?, @success, @message)', [
            $dto->normalizedQuery,
            $dto->limit,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        $suggestions = array_map(fn($row) => SearchSuggestionDto::fromRow($row), $rows);

        // TODO(Redis): SETEX la clé de cache ici avec $suggestions avant de retourner,
        // une fois la couche Redis branchée (ex: Illuminate\Support\Facades\Redis
        // ou Cache::store('redis')->put($cacheKey, $suggestions, now()->addMinutes(10))).

        return $suggestions;
    }

    public function getUserSearchHistory(GetSearchHistoryDto $dto, int $userId): array
    {
        // TODO(Redis): cache candidat surtout pour "famous" (peu de variation par IP
        // sur une courte fenêtre). Clé: "search:famous:{$dto->ipAddress}:{$dto->famousLimit}",
        // TTL court (5-10 min). Le "latest" personnel est moins pertinent à cacher
        // puisqu'il doit refléter les recherches très récentes de l'utilisateur.

        $latestRows = DB::select('CALL SP_GetUserLatestSearches(?, ?, @success1, @message1)', [
            $userId,
            $dto->latestLimit,
        ]);
        $latestResult = DB::selectOne('SELECT @success1 AS success, @message1 AS message');

        if (!$latestResult->success) {
            throw new BusinessValidationException($latestResult->message, 404);
        }

        $famousRows = DB::select('CALL SP_GetFamousSearchesByIP(?, ?, @success2, @message2)', [
            $dto->ipAddress,
            $dto->famousLimit,
        ]);
        $famousResult = DB::selectOne('SELECT @success2 AS success, @message2 AS message');

        if (!$famousResult->success) {
            throw new BusinessValidationException($famousResult->message, 422);
        }

        return [
            'latest' => array_map(fn($row) => SearchHistoryItemDto::fromRow($row), $latestRows),
            'famous' => array_map(fn($row) => SearchHistoryItemDto::fromRow($row), $famousRows),
        ];
    }

    /**
     * Enregistre / met à jour une entrée du dictionnaire de recherche.
     * À appeler au moment d'une recherche réelle (pas sur chaque keystroke
     * d'autocomplete), pour que SearchHitCount / SearchHitCount7d reflètent
     * un usage effectif plutôt que du bruit de frappe.
     */
    public function recordSearchTerm(UpsertSearchTermDto $dto): SearchTermUpsertResultDto
    {
        $rows = DB::select('CALL SP_UpsertSearchDictionary(?, ?, ?, ?)', [
            $dto->displayText,
            $dto->sourceType,
            $dto->sourceId,
            $dto->resultCount,
        ]);

        if (empty($rows)) {
            throw new BusinessValidationException('Échec de l\'enregistrement du terme de recherche.', 422);
        }

        return SearchTermUpsertResultDto::fromRow($rows[0]);
    }

    /**
     * Initialise une ligne de stats (SearchTermID, ProductID) à zéro, la première
     * fois qu'un produit apparaît dans les résultats d'un terme de recherche.
     * Retourne silencieusement null si la paire existe déjà (pas une erreur bloquante),
     * les incréments (ImpressionCount/ClickCount/...) étant gérés par une autre SP.
     */
    public function recordSearchTermProductStats(InsertSearchTermProductStatsDto $dto): ?int
    {
        $rows = DB::select('CALL SP_InsertSearchTermProductStats(?, ?, @success, @message)', [
            $dto->searchTermId,
            $dto->productId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            // Paire déjà existante -> pas une erreur métier, on ignore simplement.
            return null;
        }

        return (int) $rows[0]->SearchTermProductID;
    }
    public function logUserSearch(LogUserSearchDto $dto): void
    {
        DB::select('CALL SP_LogUserSearch(?, ?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->searchTermId,
            $dto->ipAddress,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }
    }
    /**
     * Corrige ResultCount après enrichissement full-text, SANS incrémenter
     * SearchHitCount/SearchHitCount7d ni toucher LastSearchedAt.
     * À appeler une fois le total réel (primaire + full-text) connu,
     * en complément de recordSearchTerm() qui gère déjà le compteur de hits.
     */
    public function updateSearchTermResultCount(UpdateSearchTermResultCountDto $dto): void
    {
        DB::select('CALL SP_UpdateSearchDictionaryResultCount(?, ?, @success, @message)', [
            $dto->searchTermId,
            $dto->resultCount,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 404);
        }
    }


    /**
     * Enregistre un clic sur un produit depuis les résultats de recherche.
     * Résout TermText -> SearchTermID côté SP (SearchDictionary.NormalizedText),
     * puis incrémente ClickCount et recalcule ClickThroughRate / ConversionRate
     * sur SearchTermProductStats. Upsert : crée la ligne de stats si elle
     * n'existe pas encore (clic sans impression préalable enregistrée).
     */
    public function recordSearchClick(RecordSearchClickDto $dto): void
    {
        DB::select('CALL SP_RecordSearchTermClick(?, ?, @success, @message)', [
            $dto->termText,
            $dto->productId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }
    }
}
