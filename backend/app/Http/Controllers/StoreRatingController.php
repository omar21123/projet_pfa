<?php
// App\Http\Controllers\StoreRatingController
namespace App\Http\Controllers;

use App\Http\Requests\Vendor\StoreRatingRequest;
use App\Services\Interface\StoreRatingServiceInterface;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "StoreRatings",
    description: "Avis et notes des boutiques vendeurs"
)]
class StoreRatingController extends Controller
{
    public function __construct(
        protected StoreRatingServiceInterface $storeRatingService,
    ) {}

    #[OA\Post(
        path: "/api/vendors/{vendorProfileID}/ratings",
        tags: ["StoreRatings"],
        summary: "Soumettre un avis sur une boutique",
        description: "Crée ou met à jour l'avis de l'utilisateur authentifié pour une boutique vendeur. Un utilisateur ne peut pas évaluer sa propre boutique.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "vendorProfileID",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 5
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["rating"],
            properties: [
                new OA\Property(property: "rating",  type: "integer", minimum: 1, maximum: 5, example: 4),
                new OA\Property(property: "comment", type: "string",  nullable: true, example: "Très bon vendeur, livraison rapide."),
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Avis soumis avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string",  example: "Avis soumis avec succès."),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Règle métier violée",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string",  example: "Vous ne pouvez pas évaluer votre propre boutique."),
            ]
        )
    )]
    public function store(StoreRatingRequest $request, int $vendorProfileID): JsonResponse
    {
        if ($vendorProfileID <= 0) {
            return response()->json(['success' => false, 'message' => 'Identifiant de profil vendeur invalide.'], 404);
        }

        $userPublicID = $request->attributes->get('user_id');
        $validated    = $request->validated();

        try {
            $this->storeRatingService->insert(
                userPublicID:    $userPublicID,
                vendorProfileID: $vendorProfileID,
                rating:          $validated['rating'],
                comment:         $validated['comment'] ?? null,
            );
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 422);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json(['success' => true, 'message' => 'Avis soumis avec succès.'], 201);
    }

    #[OA\Put(
        path: "/api/vendors/{vendorProfileID}/ratings",
        tags: ["StoreRatings"],
        summary: "Mettre à jour son avis",
        description: "Met à jour la note et le commentaire de l'utilisateur authentifié pour une boutique vendeur.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "vendorProfileID",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 5
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["rating"],
            properties: [
                new OA\Property(property: "rating",  type: "integer", minimum: 1, maximum: 5, example: 5),
                new OA\Property(property: "comment", type: "string",  nullable: true, example: "Finalement excellent !"),
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Avis mis à jour avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string",  example: "Avis mis à jour avec succès."),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Aucun avis trouvé pour cette boutique",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string",  example: "Aucun avis trouvé pour cette boutique."),
            ]
        )
    )]
    public function update(StoreRatingRequest $request, int $vendorProfileID): JsonResponse
    {
        if ($vendorProfileID <= 0) {
            return response()->json(['success' => false, 'message' => 'Identifiant de profil vendeur invalide.'], 404);
        }

        $userPublicID = $request->attributes->get('user_id');
        $validated    = $request->validated();

        try {
            $this->storeRatingService->update(
                userPublicID:    $userPublicID,
                vendorProfileID: $vendorProfileID,
                rating:          $validated['rating'],
                comment:         $validated['comment'] ?? null,
            );
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 422);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json(['success' => true, 'message' => 'Avis mis à jour avec succès.'], 200);
    }

    #[OA\Delete(
        path: "/api/vendors/{vendorProfileID}/ratings",
        tags: ["StoreRatings"],
        summary: "Supprimer son avis",
        description: "Supprime (soft delete) l'avis de l'utilisateur authentifié et recalcule la note moyenne.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "vendorProfileID",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 5
    )]
    #[OA\Response(
        response: 200,
        description: "Avis supprimé avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string",  example: "Avis supprimé avec succès."),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Aucun avis actif trouvé",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string",  example: "Aucun avis actif trouvé pour cette boutique."),
            ]
        )
    )]
    public function destroy(Request $request, int $vendorProfileID): JsonResponse
    {
        if ($vendorProfileID <= 0) {
            return response()->json(['success' => false, 'message' => 'Identifiant de profil vendeur invalide.'], 404);
        }

        $userPublicID = $request->attributes->get('user_id');

        try {
            $this->storeRatingService->delete($userPublicID, $vendorProfileID);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 404);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json(['success' => true, 'message' => 'Avis supprimé avec succès.'], 200);
    }

    #[OA\Get(
        path: "/api/vendors/{vendorProfileID}/ratings",
        tags: ["StoreRatings"],
        summary: "Lister les avis d'une boutique",
        description: "Retourne la liste paginée des avis d'une boutique avec nom et avatar du commentateur. Note moyenne et total dans les métadonnées.",
    )]
    #[OA\Parameter(
        name: "vendorProfileID",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 5
    )]
    #[OA\Parameter(name: "page",     in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
    #[OA\Parameter(name: "per_page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20))]
    #[OA\Response(
        response: 200,
        description: "Avis récupérés avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(
                        properties: [
                            new OA\Property(property: "RatingID",        type: "integer", example: 12),
                            new OA\Property(property: "Rating",          type: "integer", example: 5),
                            new OA\Property(property: "Comment",         type: "string",  nullable: true),
                            new OA\Property(property: "CommenterName",   type: "string",  example: "Jean Dupont"),
                            new OA\Property(property: "CommenterAvatar", type: "string",  nullable: true),
                        ]
                    )
                ),
                new OA\Property(
                    property: "meta",
                    type: "object",
                    properties: [
                        new OA\Property(property: "total",          type: "integer", example: 48),
                        new OA\Property(property: "average_rating", type: "number",  example: 4.3),
                        new OA\Property(property: "page",           type: "integer", example: 1),
                        new OA\Property(property: "page_size",      type: "integer", example: 20),
                        new OA\Property(property: "last_page",      type: "integer", example: 3),
                    ]
                ),
            ]
        )
    )]
    public function index(Request $request, int $vendorProfileID): JsonResponse
    {
        if ($vendorProfileID <= 0) {
            return response()->json(['success' => false, 'message' => 'Identifiant de profil vendeur invalide.'], 404);
        }

        $pageNumber = max(1, (int) $request->query('page', 1));
        $pageSize   = min(100, max(1, (int) $request->query('per_page', 20)));

        try {
            $result = $this->storeRatingService->getByVendor($vendorProfileID, $pageNumber, $pageSize);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 404);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json([
            'data' => array_map(fn($item) => $item->toArray(), $result['data']),
            'meta' => [
                'total'          => $result['total'],
                'average_rating' => $result['averageRating'],
                'page'           => $result['page'],
                'page_size'      => $result['pageSize'],
                'last_page'      => $result['totalPages'],
            ],
        ], 200);
    }
}