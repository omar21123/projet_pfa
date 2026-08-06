<?php

namespace App\Http\Controllers;

use App\Http\Requests\Product\GetProductRecommendationsRequest;
use App\Services\Interface\ProductRecommendationServiceInterface;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;
use Illuminate\Support\Facades\Log;

#[OA\Tag(
    name: "ProductRecommendation",
    description: "Recommandations produit (produits les plus vendus, et sources futures)"
)]
class ProductRecommendationController extends Controller
{
    public function __construct(
        private ProductRecommendationServiceInterface $productRecommendationService,
    ) {}

    #[OA\Get(
        path: "/api/products/recommendations",
        tags: ["ProductRecommendation"],
        summary: "Lister les produits recommandés",
        description: "Retourne actuellement les produits les plus vendus (commandes livrées/validées uniquement). UserPublicID est déduit du token JWT s'il est présent — route accessible aux invités, auquel cas IsLiked/IsWishedList sont toujours false."
    )]
    #[OA\Parameter(
        name: "limit",
        in: "query",
        required: false,
        schema: new OA\Schema(type: "integer", default: 20, minimum: 1, maximum: 100)
    )]
    #[OA\Parameter(
        name: "category_id",
        in: "query",
        required: false,
        schema: new OA\Schema(type: "integer", minimum: 1)
    )]
    #[OA\Response(
        response: 200,
        description: "Produits recommandés récupérés avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "data", type: "array", items: new OA\Items(type: "object")),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Erreur de validation ou lors de la récupération",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string"),
            ]
        )
    )]
   public function index(GetProductRecommendationsRequest $request): JsonResponse
{
    $publicId = $request->attributes->get('user_id');
    $validated = $request->validated();

    try {
        $ipAddress = $request->ip(); // Récupère l'adresse IP du client
        $result = $this->productRecommendationService->getRecommendations(
            $publicId,
            $validated['limit'],
            $validated['category_id'] ?? null    ,
            $ipAddress
        );
    } catch (\App\Exceptions\BusinessValidationException $e) {
        return response()->json([
            'success' => false,
            'message' => $e->getMessage(),
        ], $e->getCode() ?: 422);
    } catch (\Throwable $e) {
        return response()->json([
            'success' => false,
            'message' => $e->getMessage(),
        ], 500);
    }
    Log::info('Product recommendations retrieved successfully', [
        'user_id' => $publicId,
        'limit' => $validated['limit'],
        'category_id' => $validated['category_id'] ?? null,
        'result_count' => count($result->mostSold) + count($result->mostViewed) + count($result->promotions) + count($result->trending),
    ]);
    return response()->json([
        'success' => true,
        'data' => $result->toArray(), // ⬅ plus de array_map ici, le DTO gère déjà sa forme
    ], 200);
}
}