<?php

namespace App\Http\Controllers;

use App\DTOs\Search\SearchSuggestionsQueryDto;
use App\Http\Requests\Search\SearchSuggestionsRequest;
use App\Services\Interface\SearchServiceInterface;
use App\Services\Interface\UserServiceInterface;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;

#[OA\Tag(name: "Search", description: "Recherche et suggestions")]
class SearchController extends Controller
{
    public function __construct(
        protected SearchServiceInterface $searchService,
        private UserServiceInterface $userService,
    ) {}

    #[OA\Get(
        path: "/api/search/suggestions",
        tags: ["Search"],
        summary: "Suggestions de recherche (autocomplétion)",
        description: "Retourne les termes de recherche les plus pertinents commençant par la requête donnée, triés par popularité (7 derniers jours, puis historique global). Endpoint public, sans authentification."
    )]
    #[OA\Parameter(name: "q", in: "query", required: true, description: "Texte tapé par l'utilisateur (min. 2 caractères).", schema: new OA\Schema(type: "string", minLength: 2, maxLength: 150), example: "écout")]
    #[OA\Parameter(name: "limit", in: "query", required: false, description: "Nombre maximum de suggestions (défaut 10, max 20).", schema: new OA\Schema(type: "integer", default: 10, maximum: 20))]
    #[OA\Response(
        response: 200,
        description: "Suggestions récupérées avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "data", type: "array", items: new OA\Items(
                    properties: [new OA\Property(property: "text", type: "string", example: "écouteurs sans fil")]
                )),
            ]
        )
    )]
    #[OA\Response(response: 422, description: "Requête invalide (trop courte)")]
    public function suggestions(SearchSuggestionsRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $dto = SearchSuggestionsQueryDto::fromArray([
            'Query' => $validated['q'],
            'Limit' => $validated['limit'] ?? 10,
        ]);

        try {
            $result = $this->searchService->getSuggestions($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 422);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json([
            'success' => true,
            'data' => array_map(fn($s) => $s->toArray(), $result),
        ], 200);
    }
    #[OA\Get(
        path: "/api/search/history",
        tags: ["Search"],
        summary: "Historique de recherche de l'utilisateur",
        description: "Retourne les recherches les plus récentes de l'utilisateur connecté, ainsi que les recherches les plus populaires émises depuis son adresse IP actuelle.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "latest_limit", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 10, maximum: 50))]
    #[OA\Parameter(name: "famous_limit", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 10, maximum: 50))]
    #[OA\Response(
        response: 200,
        description: "Historique récupéré avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "latest", type: "array", items: new OA\Items(type: "object")),
                        new OA\Property(property: "famous", type: "array", items: new OA\Items(type: "object")),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(response: 404, description: "Utilisateur introuvable")]
    public function history(Request $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');

        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable.'
            ], 404);
        }

        $dto = GetSearchHistoryDto::fromArray([
            'UserPublicID' => $publicId,
            'IPAddress'    => $request->ip(),
            'LatestLimit'  => $request->query('latest_limit', 10),
            'FamousLimit'  => $request->query('famous_limit', 10),
        ]);

        try {
            $result = $this->searchService->getUserSearchHistory($dto, $userInfo->UserID);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 404);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'latest' => array_map(fn($s) => $s->toArray(), $result['latest']),
                'famous' => array_map(fn($s) => $s->toArray(), $result['famous']),
            ],
        ], 200);
    }
}
