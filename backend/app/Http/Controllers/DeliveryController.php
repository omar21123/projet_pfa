<?php
// app/Http/Controllers/DeliveryController.php

namespace App\Http\Controllers;

use App\DTOs\Delivery\GetAllDeliveryProfilesDto;
use App\Http\Requests\Delivery\GetAllDeliveryProfilesRequest;
use App\Services\Interface\DeliveryServiceInterface;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Deliveries",
    description: "Gestion des livreurs et des livraisons"
)]
class DeliveryController extends Controller
{
    public function __construct(
        protected DeliveryServiceInterface $deliveryService,
    ) {}

    #[OA\Get(
        path: "/api/deliveries/profiles",
        tags: ["Deliveries"],
        summary: "Lister les profils livreurs (admin)",
        description: "Retourne la liste paginée des livreurs avec leurs informations utilisateur, statistiques et statut de disponibilité/approbation. Filtrable par recherche (nom, email, plaque), disponibilité, approbation et suspension.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "search", in: "query", required: false, schema: new OA\Schema(type: "string"), example: "Youssef")]
    #[OA\Parameter(name: "is_available", in: "query", required: false, schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "is_approved", in: "query", required: false, schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "is_suspended", in: "query", required: false, schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
    #[OA\Parameter(name: "per_page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20))]
    #[OA\Response(
        response: 200,
        description: "Liste des livreurs récupérée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(
                        properties: [
                            new OA\Property(property: "delivery_profile_id", type: "integer", example: 7),
                            new OA\Property(property: "avatar_url", type: "string", nullable: true),
                            new OA\Property(property: "display_name", type: "string", example: "Youssef El Amrani"),
                            new OA\Property(property: "email", type: "string", example: "youssef@example.com"),
                            new OA\Property(property: "vehicle_type", type: "string", nullable: true, example: "moto"),
                            new OA\Property(property: "license_plate", type: "string", nullable: true, example: "12345-A-6"),
                            new OA\Property(property: "rating", type: "number", format: "float", example: 4.8),
                            new OA\Property(property: "delivery_count", type: "integer", example: 132),
                            new OA\Property(property: "identity_verified", type: "boolean", example: true),
                            new OA\Property(property: "last_login_at", type: "string", format: "date-time", nullable: true),
                            new OA\Property(property: "is_available", type: "boolean", example: true),
                            new OA\Property(property: "is_approved", type: "boolean", example: true),
                        ]
                    )
                ),
                new OA\Property(
                    property: "meta",
                    type: "object",
                    properties: [
                        new OA\Property(property: "total", type: "integer", example: 48),
                        new OA\Property(property: "page", type: "integer", example: 1),
                        new OA\Property(property: "page_size", type: "integer", example: 20),
                        new OA\Property(property: "last_page", type: "integer", example: 3),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Règle métier violée",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string"),
            ]
        )
    )]
    public function index(GetAllDeliveryProfilesRequest $request): JsonResponse
    {
        $dto = GetAllDeliveryProfilesDto::fromRequest($request->validated());

        try {
            $result = $this->deliveryService->getAllDeliveryProfiles($dto);
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