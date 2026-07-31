<?php

namespace App\Repositories\sql;

use App\DTOs\Search\SearchSuggestionsQueryDto;
use App\DTOs\Search\SearchSuggestionDto;
use App\Repositories\Interface\SearchRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;

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
}