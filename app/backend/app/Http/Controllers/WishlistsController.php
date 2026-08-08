<?php

namespace App\Http\Controllers;

use App\DTOs\Wishlist\CreateWishlistDto;
use App\DTOs\Wishlist\AddWishlistItemDto;
use App\DTOs\Wishlist\RemoveWishlistItemDto;
use App\DTOs\Wishlist\DeleteWishlistDto;
use App\Http\Requests\Wishlist\CreateWishlistRequest;
use App\Http\Requests\Wishlist\AddWishlistItemRequest;
use App\Services\Interface\WishlistServiceInterface;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Wishlists",
    description: "Gestion des wishlists de l'utilisateur (création, ajout/suppression d'items, suppression)"
)]
class WishlistsController extends Controller
{
    public function __construct(
        private WishlistServiceInterface $wishlistService,
    ) {}

    #[OA\Get(
        path: "/api/wishlists",
        tags: ["Wishlists"],
        summary: "Lister les wishlists de l'utilisateur connecté",
        description: "Retourne toutes les wishlists de l'utilisateur authentifié, chacune avec ses items rattachés et un compteur d'items. UserPublicID est déduit du token JWT.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Response(
        response: 200,
        description: "Liste des wishlists récupérée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(
                        properties: [
                            new OA\Property(property: "wishListId", type: "integer", example: 7),
                            new OA\Property(property: "name", type: "string", example: "My Wishlist"),
                            new OA\Property(property: "isDefault", type: "boolean", example: true),
                            new OA\Property(property: "createdAt", type: "string", format: "date-time"),
                            new OA\Property(property: "itemCount", type: "integer", example: 3),
                            new OA\Property(
                                property: "items",
                                type: "array",
                                items: new OA\Items(
                                    properties: [
                                        new OA\Property(property: "wishListItemId", type: "integer", example: 42),
                                        new OA\Property(property: "wishListId", type: "integer", example: 7),
                                        new OA\Property(property: "productId", type: "integer", example: 123),
                                        new OA\Property(property: "productName", type: "string", example: "Clavier Mécanique RGB"),
                                        new OA\Property(property: "productImage", type: "string", nullable: true, example: "/storage/products/123/main.jpg"),
                                        new OA\Property(property: "basePrice", type: "number", format: "float", example: 349.99),
                                        new OA\Property(property: "brandName", type: "string", nullable: true, example: "Logitech"),
                                        new OA\Property(property: "createdAt", type: "string", format: "date-time"),
                                    ]
                                )
                            ),
                        ]
                    )
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 401,
        description: "Non authentifié",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Non authentifié."),
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
    // GET /wishlists
    public function index(Request $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');

        try {
            $wishlists = $this->wishlistService->getUserWishlists($publicId);
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
            'data' => $wishlists,
        ], 200);
    }

    #[OA\Post(
        path: "/api/wishlists",
        tags: ["Wishlists"],
        summary: "Créer une nouvelle wishlist",
        description: "Crée une wishlist pour l'utilisateur connecté. Si 'name' est omis, 'My Wishlist' est utilisé. La toute première wishlist d'un utilisateur devient automatiquement sa wishlist par défaut (isDefault = true). UserPublicID est déduit du token JWT.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: false,
        content: new OA\JsonContent(
            properties: [
                new OA\Property(
                    property: "name",
                    type: "string",
                    maxLength: 150,
                    nullable: true,
                    description: "Nom de la wishlist. Défaut : 'My Wishlist'.",
                    example: "Cadeaux de Noël"
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Wishlist créée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Wishlist créée avec succès."),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "wishListId", type: "integer", example: 7),
                        new OA\Property(property: "name", type: "string", example: "Cadeaux de Noël"),
                        new OA\Property(property: "isDefault", type: "boolean", example: false),
                        new OA\Property(property: "createdAt", type: "string", format: "date-time"),
                        new OA\Property(property: "itemCount", type: "integer", example: 0),
                    ]
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
    #[OA\Response(
        response: 422,
        description: "Erreur de validation",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string"),
            ]
        )
    )]
    // POST /wishlists
    public function store(CreateWishlistRequest $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');
        $validated = $request->validated();

        $dto = CreateWishlistDto::fromArray([
            'userPublicId' => $publicId,
            'name'         => $validated['name'] ?? null,
        ]);

        try {
            $wishlist = $this->wishlistService->create($dto);
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
            'message' => 'Wishlist créée avec succès.',
            'data' => $wishlist,
        ], 201);
    }

    #[OA\Post(
        path: "/api/wishlists/{wishListId}/items",
        tags: ["Wishlists"],
        summary: "Ajouter un produit à une wishlist",
        description: "Ajoute un produit à la wishlist spécifiée. La wishlist doit appartenir à l'utilisateur connecté (vérifié via le token JWT), et le produit ne doit pas déjà y figurer.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "wishListId",
        in: "path",
        required: true,
        description: "Identifiant de la wishlist cible.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 7
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
        description: "Produit ajouté à la wishlist avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Produit ajouté à la wishlist."),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "wishListItemId", type: "integer", example: 42),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 403,
        description: "Accès refusé : cette wishlist ne vous appartient pas",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Accès refusé : cette wishlist ne vous appartient pas."),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur, wishlist ou produit introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Wishlist introuvable."),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Erreur de validation ou produit déjà présent dans la wishlist",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Ce produit est déjà dans cette wishlist."),
            ]
        )
    )]
    // POST /wishlists/{wishListId}/items
    public function addItem(AddWishlistItemRequest $request, int $wishListId): JsonResponse
    {
        if ($wishListId <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de wishlist invalide.',
            ], 404);
        }

        $publicId = $request->attributes->get('user_id');
        $validated = $request->validated();

        $dto = AddWishlistItemDto::fromArray([
            'userPublicId' => $publicId,
            'wishListId'   => $wishListId,
            'productId'    => $validated['product_id'],
        ]);

        try {
            $result = $this->wishlistService->addItem($dto);
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
            'message' => 'Produit ajouté à la wishlist.',
            'data' => $result,
        ], 201);
    }

    #[OA\Delete(
        path: "/api/wishlists/items/{wishListItemId}",
        tags: ["Wishlists"],
        summary: "Retirer un produit d'une wishlist",
        description: "Supprime définitivement un item de wishlist (suppression réelle, pas de soft-delete). L'item doit appartenir à une wishlist de l'utilisateur connecté.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "wishListItemId",
        in: "path",
        required: true,
        description: "Identifiant de l'item de wishlist à supprimer.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 42
    )]
    #[OA\Response(
        response: 200,
        description: "Item supprimé avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Produit retiré de la wishlist."),
            ]
        )
    )]
    #[OA\Response(
        response: 403,
        description: "Accès refusé : cet élément ne vous appartient pas",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Accès refusé : cet élément ne vous appartient pas."),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur ou élément introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Élément introuvable."),
            ]
        )
    )]
    // DELETE /wishlists/items/{wishListItemId}
    public function removeItem(Request $request, int $wishListItemId): JsonResponse
    {
        if ($wishListItemId <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant d\'élément invalide.',
            ], 404);
        }

        $publicId = $request->attributes->get('user_id');

        $dto = RemoveWishlistItemDto::fromArray([
            'userPublicId'   => $publicId,
            'wishListItemId' => $wishListItemId,
        ]);

        try {
            $this->wishlistService->removeItem($dto);
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
            'message' => 'Produit retiré de la wishlist.',
        ], 200);
    }

    #[OA\Delete(
        path: "/api/wishlists/{wishListId}",
        tags: ["Wishlists"],
        summary: "Supprimer une wishlist entière",
        description: "Supprime définitivement la wishlist et tous ses items (suppression réelle en cascade, pas de soft-delete). La wishlist doit appartenir à l'utilisateur connecté.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "wishListId",
        in: "path",
        required: true,
        description: "Identifiant de la wishlist à supprimer.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 7
    )]
    #[OA\Response(
        response: 200,
        description: "Wishlist et ses items supprimés avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Wishlist supprimée avec succès."),
            ]
        )
    )]
    #[OA\Response(
        response: 403,
        description: "Accès refusé : cette wishlist ne vous appartient pas",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Accès refusé : cette wishlist ne vous appartient pas."),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur ou wishlist introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Wishlist introuvable."),
            ]
        )
    )]
    // DELETE /wishlists/{wishListId}
    public function destroy(Request $request, int $wishListId): JsonResponse
    {
        if ($wishListId <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de wishlist invalide.',
            ], 404);
        }

        $publicId = $request->attributes->get('user_id');

        $dto = DeleteWishlistDto::fromArray([
            'userPublicId' => $publicId,
            'wishListId'   => $wishListId,
        ]);

        try {
            $this->wishlistService->delete($dto);
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
            'message' => 'Wishlist supprimée avec succès.',
        ], 200);
    }
}