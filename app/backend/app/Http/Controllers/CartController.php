<?php

namespace App\Http\Controllers;

use App\DTOs\Cart\AddCartItemDto;
use App\DTOs\Cart\RemoveCartItemDto;
use App\Exceptions\BusinessValidationException;
use App\Http\Requests\Cart\AddCartItemRequest;
use App\Http\Requests\Cart\RemoveCartItemRequest;
use App\Services\Interface\CartServiceInterface;
use Illuminate\Http\JsonResponse;
use App\DTOs\Cart\GetCartDto;
use App\DTOs\Cart\UpdateCartItemQuantityDto;
use App\Http\Requests\Cart\GetCartRequest;
use App\Http\Requests\Cart\UpdateCartItemQuantityRequest;
use OpenApi\Attributes as OA;

class CartController extends Controller
{
    public function __construct(
        protected CartServiceInterface $cartService
    ) {}

    #[OA\Post(
        path: "/api/cart/items",
        tags: ["Cart"],
        summary: "Ajouter un produit au panier",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["productID", "UnitPrice"],
            properties: [
                new OA\Property(property: "productID", type: "integer", example: 12345),

                new OA\Property(property: "FromSearch", type: "boolean", nullable: true, example: true),
                new OA\Property(property: "SearchTerm", type: "string", nullable: true, example: "example search term"),
                new OA\Property(property: "CompositionID", type: "integer", nullable: true, example: 10),
                new OA\Property(
                    property: "Quantity",
                    type: "number",
                    format: "float",
                    nullable: true,
                    minimum: 0,
                    default: 1,
                    example: 2,
                    description: "Quantité à ajouter au panier. Si null, absente ou <= 0, une valeur de 1 est appliquée par défaut."
                ),
                new OA\Property(property: "UnitPrice", type: "number", format: "float", example: 19.99),
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Produit ajouté au panier",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Produit ajouté au panier."),
            ]
        )
    )]
    #[OA\Response(response: 404, description: "Produit ou combinaison introuvable")]
    #[OA\Response(response: 422, description: "Erreur de validation")]
    public function addItem(AddCartItemRequest $request): JsonResponse
    {
        $userPublicId = $request->attributes->get('user_id');
        $dto = AddCartItemDto::fromArray($request->validated(), $userPublicId);

        try {
            $message = $this->cartService->addItem($dto);
        } catch (BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => $message,
        ], 200);
    }




    #[OA\Delete(
        path: "/api/cart/items",
        tags: ["Cart"],
        summary: "Retirer un produit du panier",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["productID"],
            properties: [
                new OA\Property(property: "productID", type: "integer", example: 12345),
                new OA\Property(property: "CompositionID", type: "integer", nullable: true, example: 10),
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Article supprimé du panier",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Article supprimé du panier."),
            ]
        )
    )]
    #[OA\Response(response: 404, description: "Utilisateur, panier ou article introuvable")]
    public function removeItem(RemoveCartItemRequest $request): JsonResponse
    {
        $userPublicId = $request->attributes->get('user_id');
        $dto = RemoveCartItemDto::fromArray($request->validated(), $userPublicId);

        try {
            $message = $this->cartService->removeItem($dto);
        } catch (BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => $message,
        ], 200);
    }


    #[OA\Get(
        path: "/api/cart",
        tags: ["Cart"],
        summary: "Récupérer le contenu du panier de l'utilisateur",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Response(
        response: 200,
        description: "Contenu du panier",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "data", type: "array", items: new OA\Items(type: "object")),
            ]
        )
    )]
    public function getCart(GetCartRequest $request): JsonResponse
    {
        $userPublicId = $request->attributes->get('user_id');
        $dto = new GetCartDto($userPublicId);

        $response = $this->cartService->getCart($dto);

        return response()->json([
            'success' => true,
            'data'    => $response,
        ], 200);
    }
    #[OA\Patch(
        path: "/api/cart/items/quantity",
        tags: ["Cart"],
        summary: "Modifier la quantité d'un article du panier",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["CartItemID", "Quantity"],
            properties: [
                new OA\Property(property: "CartItemID", type: "integer", example: 42),
                new OA\Property(
                    property: "Quantity",
                    type: "number",
                    format: "float",
                    example: 3,
                    description: "Nouvelle quantité. Une valeur de 0 (ou négative) retire l'article du panier."
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Quantité mise à jour (ou article retiré si Quantity <= 0)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Quantité mise à jour."),
            ]
        )
    )]
    #[OA\Response(response: 403, description: "Cet article n'appartient pas à votre panier")]
    #[OA\Response(response: 404, description: "Utilisateur, panier ou article introuvable")]
    #[OA\Response(response: 422, description: "Erreur de validation")]
    public function updateItemQuantity(UpdateCartItemQuantityRequest $request): JsonResponse
    {
        $userPublicId = $request->attributes->get('user_id');
        $dto = UpdateCartItemQuantityDto::fromArray($request->validated(), $userPublicId);

        try {
            $message = $this->cartService->updateItemQuantity($dto);
        } catch (BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => $message,
        ], 200);
    }
}
