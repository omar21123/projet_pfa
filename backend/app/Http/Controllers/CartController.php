<?php

namespace App\Http\Controllers;

use App\DTOs\Cart\AddCartItemDto;
use App\Exceptions\BusinessValidationException;
use App\Http\Requests\Cart\AddCartItemRequest;
use App\Services\Interface\CartServiceInterface;
use Illuminate\Http\JsonResponse;
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
}