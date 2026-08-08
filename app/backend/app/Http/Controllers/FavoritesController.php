<?php

namespace App\Http\Controllers;

use App\DTOs\ProductLike\AddProductLikeDto;
use App\DTOs\ProductLike\RemoveProductLikeDto;
use App\Http\Requests\ProductLike\AddProductLikeRequest;
use App\Services\Interface\ProductLikeServiceInterface;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Favorites",
    description: "Gestion des produits favoris de l'utilisateur (ajout, suppression, liste)"
)]
class FavoritesController extends Controller
{
    public function __construct(
        private ProductLikeServiceInterface $productLikeService,
    ) {}

    #[OA\Get(
        path: "/api/favorites",
        tags: ["Favorites"],
        summary: "Lister les produits favoris de l'utilisateur connecté",
        description: "Retourne tous les produits likés par l'utilisateur authentifié, triés du plus récent au plus ancien. UserPublicID est déduit du token JWT.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Response(
        response: 200,
        description: "Liste des favoris récupérée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(
                        properties: [
                            new OA\Property(property: "productLikeId", type: "integer", example: 15),
                            new OA\Property(property: "productId", type: "integer", example: 123),
                            new OA\Property(property: "productName", type: "string", example: "Clavier Mécanique RGB"),
                            new OA\Property(property: "productImage", type: "string", nullable: true, example: "/storage/products/123/main.jpg"),
                            new OA\Property(property: "basePrice", type: "number", format: "float", example: 349.99),
                            new OA\Property(property: "brandName", type: "string", nullable: true, example: "Logitech"),
                            new OA\Property(property: "likedAt", type: "string", format: "date-time"),
                        ]
                    )
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Utilisateur introuvable."),
            ]
        )
    )]
    // GET /favorites
    public function index(Request $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');

        try {
            $likes = $this->productLikeService->getUserLikes($publicId);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 404);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'data' => $likes,
        ], 200);
    }

    #[OA\Post(
        path: "/api/favorites",
        tags: ["Favorites"],
        summary: "Ajouter un produit aux favoris",
        description: "Ajoute un produit aux favoris de l'utilisateur connecté. Le produit ne doit pas déjà être liké. UserPublicID est déduit du token JWT.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["product_id"],
            properties: [
                new OA\Property(property: "product_id", type: "integer", example: 123),
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Produit ajouté aux favoris avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Produit ajouté aux favoris."),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "productLikeId", type: "integer", example: 15),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur ou produit introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Produit introuvable."),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Erreur de validation ou produit déjà liké",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Vous aimez déjà ce produit."),
            ]
        )
    )]
    // POST /favorites
    public function store(AddProductLikeRequest $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');
        $validated = $request->validated();

        $dto = AddProductLikeDto::fromArray([
            'userPublicId' => $publicId,
            'productId'    => $validated['product_id'],
        ]);

        try {
            $result = $this->productLikeService->addLike($dto);
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

        return response()->json([
            'success' => true,
            'message' => 'Produit ajouté aux favoris.',
            'data' => $result,
        ], 201);
    }

    #[OA\Delete(
        path: "/api/favorites/{productId}",
        tags: ["Favorites"],
        summary: "Retirer un produit des favoris",
        description: "Supprime définitivement un like (suppression réelle, pas de soft-delete). Le favori doit appartenir à l'utilisateur connecté.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "productId",
        in: "path",
        required: true,
        description: "Identifiant du produit à retirer des favoris.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 123
    )]
    #[OA\Response(
        response: 200,
        description: "Favori supprimé avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Produit retiré des favoris."),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur introuvable ou produit non liké",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Ce produit n'est pas dans vos favoris."),
            ]
        )
    )]
    // DELETE /favorites/{productId}
    public function destroy(Request $request, int $productId): JsonResponse
    {
        if ($productId <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de produit invalide.',
            ], 404);
        }

        $publicId = $request->attributes->get('user_id');

        $dto = RemoveProductLikeDto::fromArray([
            'userPublicId' => $publicId,
            'productId'    => $productId,
        ]);

        try {
            $this->productLikeService->removeLike($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 404);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Produit retiré des favoris.',
        ], 200);
    }
}