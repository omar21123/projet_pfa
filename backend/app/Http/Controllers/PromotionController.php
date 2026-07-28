<?php

namespace App\Http\Controllers;

use App\Services\Interface\PromotionServiceInterface;
use App\Services\Interface\UserServiceInterface;
use App\Services\Interface\VendorServiceInterface;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;

#[OA\Tag(name: "Promotions", description: "Gestion des promotions")]
class PromotionController extends Controller
{
    public function __construct(
        protected PromotionServiceInterface $promotionService,
        private UserServiceInterface $userService,
        private VendorServiceInterface $vendorService,
    ) {}

    #[OA\Get(
        path: "/api/promotions/lookups",
        tags: ["Promotions"],
        summary: "Lister les valeurs de référence (types de réduction, portées, statuts)",
        description: "Retourne les listes de valeurs utilisées pour construire les formulaires de création/édition de promotions.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Response(
        response: 200,
        description: "Valeurs récupérées avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "discount_types", type: "array", items: new OA\Items(
                            properties: [
                                new OA\Property(property: "id", type: "integer", example: 1),
                                new OA\Property(property: "code", type: "string", example: "PERCENTAGE"),
                                new OA\Property(property: "label", type: "string", example: "Pourcentage"),
                            ]
                        )),
                        new OA\Property(property: "scope_types", type: "array", items: new OA\Items(type: "object")),
                        new OA\Property(property: "statuses", type: "array", items: new OA\Items(type: "object")),
                    ]
                ),
            ]
        )
    )]
    public function lookups(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => [
                'discount_types' => array_map(fn($d) => $d->toArray(), $this->promotionService->getDiscountTypes()),
                'scope_types'    => array_map(fn($d) => $d->toArray(), $this->promotionService->getScopeTypes()),
                'statuses'       => array_map(fn($d) => $d->toArray(), $this->promotionService->getStatuses()),
            ],
        ], 200);
    }
}