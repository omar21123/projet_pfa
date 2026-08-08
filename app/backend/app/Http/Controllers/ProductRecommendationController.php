<?php

namespace App\Http\Controllers;

use App\DTOs\Product\LoadMoreProductsQueryDto;
use App\Http\Requests\Product\GetProductRecommendationsRequest;
use App\Http\Requests\Product\LoadMoreProductsRequest;
use App\Services\Interface\ProductRecommendationServiceInterface;
use App\Services\IpWhoIsLocationService;
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
        private IpWhoIsLocationService $whoisService
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
                $validated['category_id'] ?? null,
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
#[OA\Get(path: "/api/products/most-sold/load-more", tags: ["ProductRecommendation"], summary: "Load more — produits les plus vendus")]
#[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
#[OA\Parameter(name: "page_size", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20, maximum: 100))]
#[OA\Parameter(name: "category_id", in: "query", required: false, schema: new OA\Schema(type: "integer"))]
#[OA\Response(
    response: 200,
    description: "Page suivante des produits les plus vendus",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "items", type: "array", items: new OA\Items(type: "object")),
            new OA\Property(property: "page", type: "integer", example: 1),
            new OA\Property(property: "pageSize", type: "integer", example: 20),
            new OA\Property(property: "total", type: "integer", example: 84),
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
public function loadMoreMostSold(LoadMoreProductsRequest $request): JsonResponse
{
    return $this->respond(fn($dto) => $this->productRecommendationService->loadMoreMostSoldProducts($dto), $request);
}

#[OA\Get(path: "/api/products/most-viewed/load-more", tags: ["ProductRecommendation"], summary: "Load more — produits les plus vus")]
#[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
#[OA\Parameter(name: "page_size", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20, maximum: 100))]
#[OA\Parameter(name: "category_id", in: "query", required: false, schema: new OA\Schema(type: "integer"))]
#[OA\Response(
    response: 200,
    description: "Page suivante des produits les plus vus",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "items", type: "array", items: new OA\Items(type: "object")),
            new OA\Property(property: "page", type: "integer", example: 1),
            new OA\Property(property: "pageSize", type: "integer", example: 20),
            new OA\Property(property: "total", type: "integer", example: 84),
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
public function loadMoreMostViewed(LoadMoreProductsRequest $request): JsonResponse
{
    return $this->respond(fn($dto) => $this->productRecommendationService->loadMoreMostViewedProducts($dto), $request);
}

#[OA\Get(path: "/api/products/most-promoted/load-more", tags: ["ProductRecommendation"], summary: "Load more — produits les plus promus")]
#[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
#[OA\Parameter(name: "page_size", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20, maximum: 100))]
#[OA\Parameter(name: "category_id", in: "query", required: false, schema: new OA\Schema(type: "integer"))]
#[OA\Response(
    response: 200,
    description: "Page suivante des produits les plus promus",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "items", type: "array", items: new OA\Items(type: "object")),
            new OA\Property(property: "page", type: "integer", example: 1),
            new OA\Property(property: "pageSize", type: "integer", example: 20),
            new OA\Property(property: "total", type: "integer", example: 84),
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
public function loadMoreMostPromoted(LoadMoreProductsRequest $request): JsonResponse
{
    return $this->respond(fn($dto) => $this->productRecommendationService->loadMoreMostPromotedProducts($dto), $request);
}

#[OA\Get(path: "/api/products/trending/load-more", tags: ["ProductRecommendation"], summary: "Load more — produits tendance")]
#[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
#[OA\Parameter(name: "page_size", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20, maximum: 100))]
#[OA\Parameter(name: "category_id", in: "query", required: false, schema: new OA\Schema(type: "integer"))]
#[OA\Response(
    response: 200,
    description: "Page suivante des produits tendance",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "items", type: "array", items: new OA\Items(type: "object")),
            new OA\Property(property: "page", type: "integer", example: 1),
            new OA\Property(property: "pageSize", type: "integer", example: 20),
            new OA\Property(property: "total", type: "integer", example: 84),
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
public function loadMoreTrending(LoadMoreProductsRequest $request): JsonResponse
{
    return $this->respond(fn($dto) => $this->productRecommendationService->loadMoreTrendingProducts($dto), $request);
}

#[OA\Get(path: "/api/products/last-activity/load-more", tags: ["ProductRecommendation"], summary: "Load more — produits liés à l'activité récente")]
#[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
#[OA\Parameter(name: "page_size", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20, maximum: 100))]
#[OA\Parameter(name: "category_id", in: "query", required: false, schema: new OA\Schema(type: "integer"))]
#[OA\Response(
    response: 200,
    description: "Page suivante des produits liés à l'activité récente",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "items", type: "array", items: new OA\Items(type: "object")),
            new OA\Property(property: "page", type: "integer", example: 1),
            new OA\Property(property: "pageSize", type: "integer", example: 20),
            new OA\Property(property: "total", type: "integer", example: 84),
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
public function loadMoreLastActivity(LoadMoreProductsRequest $request): JsonResponse
{
    $validated = $request->validated();

    $dto = LoadMoreProductsQueryDto::fromArray([
        'userPublicId' => $request->attributes->get('user_id'),
        'pageNumber'   => $validated['page'],
        'pageSize'     => $validated['page_size'],
        'categoryId'   => $validated['category_id'] ?? null,
        'ipAddress'    => $request->ip(),
    ]);

    return $this->handleLoadMore(fn() => $this->productRecommendationService->loadMoreLastActivityProducts($dto));
}

#[OA\Get(path: "/api/products/popular-in-region/load-more", tags: ["ProductRecommendation"], summary: "Load more — produits populaires dans votre région")]
#[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
#[OA\Parameter(name: "page_size", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20, maximum: 100))]
#[OA\Parameter(name: "category_id", in: "query", required: false, schema: new OA\Schema(type: "integer"))]
#[OA\Response(
    response: 200,
    description: "Page suivante des produits populaires dans la région du visiteur (résolue via IP)",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "items", type: "array", items: new OA\Items(type: "object")),
            new OA\Property(property: "page", type: "integer", example: 1),
            new OA\Property(property: "pageSize", type: "integer", example: 20),
            new OA\Property(property: "total", type: "integer", example: 84),
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
public function loadMorePopularInRegion(LoadMoreProductsRequest $request): JsonResponse
{
    $validated = $request->validated();

    $region = $this->whoisService->locate($request->ip());
    $dto = LoadMoreProductsQueryDto::fromArray([
        'userPublicId' => $request->attributes->get('user_id'),
        'pageNumber'   => $validated['page'],
        'pageSize'     => $validated['page_size'],
        'categoryId'   => $validated['category_id'] ?? null,
        'countryCode'  => $region?->countryCode,
        'region'       => $region?->region,
    ]);

    return $this->handleLoadMore(fn() => $this->productRecommendationService->loadMorePopularInYourRegion($dto));
}

#[OA\Get(path: "/api/products/new/load-more", tags: ["ProductRecommendation"], summary: "Load more — nouveaux produits")]
#[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
#[OA\Parameter(name: "page_size", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20, maximum: 100))]
#[OA\Parameter(name: "category_id", in: "query", required: false, schema: new OA\Schema(type: "integer"))]
#[OA\Parameter(name: "days_back", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 7))]
#[OA\Response(
    response: 200,
    description: "Page suivante des nouveaux produits",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "items", type: "array", items: new OA\Items(type: "object")),
            new OA\Property(property: "page", type: "integer", example: 1),
            new OA\Property(property: "pageSize", type: "integer", example: 20),
            new OA\Property(property: "total", type: "integer", example: 84),
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
public function loadMoreNew(LoadMoreProductsRequest $request): JsonResponse
{
    $validated = $request->validated();

    $dto = LoadMoreProductsQueryDto::fromArray([
        'userPublicId' => $request->attributes->get('user_id'),
        'pageNumber'   => $validated['page'],
        'pageSize'     => $validated['page_size'],
        'categoryId'   => $validated['category_id'] ?? null,
        'daysBack'     => $validated['days_back'] ?? null,
    ]);

    return $this->handleLoadMore(fn() => $this->productRecommendationService->loadMoreNewProducts($dto));
}
    /**
     * Factorise le mapping DTO -> appel service -> réponse JSON pour les
     * sources qui n'ont besoin que de userPublicId/page/pageSize/categoryId.
     */
    private function respond(callable $call, LoadMoreProductsRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $dto = LoadMoreProductsQueryDto::fromArray([
            'userPublicId' => $request->attributes->get('user_id'),
            'pageNumber'   => $validated['page'],
            'pageSize'     => $validated['page_size'],
            'categoryId'   => $validated['category_id'] ?? null,
        ]);

        return $this->handleLoadMore(fn() => $call($dto));
    }

    private function handleLoadMore(callable $call): JsonResponse
    {
        try {
            $result = $call();
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

        return response()->json($result->toArray(), 200);
    }
}
