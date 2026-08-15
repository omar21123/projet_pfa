<?php
// app/Http/Controllers/DeliveryController.php

namespace App\Http\Controllers;

use App\DTOs\Delivery\ApproveDeliveryProfileDto;
use App\DTOs\Delivery\GetAllDeliveryProfilesDto;
use App\DTOs\Delivery\GetRecommendedDeliveriesDto;
use App\DTOs\Delivery\SuspendDeliveryProfileDto;
use App\DTOs\Delivery\UpdateDeliveryLocationDto;
use App\Http\Requests\Delivery\ApproveDeliveryProfileRequest;
use App\Http\Requests\Delivery\GetAllDeliveryProfilesRequest;
use App\Http\Requests\Delivery\GetRecommendedDeliveriesRequest;
use App\Http\Requests\Delivery\SuspendDeliveryProfileRequest;
use App\Http\Requests\Delivery\UpdateDeliveryLocationRequest;
use App\Services\Interface\DeliveryServiceInterface;
use App\Services\UserService;
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
        protected UserService $userService
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
    #[OA\Get(
        path: "/api/deliveries/profiles/{deliveryProfile}",
        tags: ["Deliveries"],
        summary: "Détails d'un livreur",
        description: "Retourne les informations complètes d'un livreur : profil utilisateur, statistiques de livraison, statut de disponibilité/approbation et solde du portefeuille.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "deliveryProfile",
        in: "path",
        required: true,
        description: "Identifiant du profil livreur.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 7
    )]
    #[OA\Response(
        response: 200,
        description: "Livreur récupéré avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "delivery_profile_id", type: "integer", example: 7),
                        new OA\Property(
                            property: "user",
                            type: "object",
                            properties: [
                                new OA\Property(property: "user_id", type: "integer", example: 34),
                                new OA\Property(property: "public_id", type: "string", example: "b3e1f7a2-..."),
                                new OA\Property(property: "first_name", type: "string", example: "Youssef"),
                                new OA\Property(property: "last_name", type: "string", example: "El Amrani"),
                                new OA\Property(property: "display_name", type: "string", example: "Youssef El Amrani"),
                                new OA\Property(property: "email", type: "string", example: "youssef@example.com"),
                                new OA\Property(property: "phone_number", type: "string", nullable: true, example: "+212600000000"),
                                new OA\Property(property: "avatar_url", type: "string", nullable: true),
                                new OA\Property(property: "email_verified", type: "boolean", example: true),
                                new OA\Property(property: "phone_verified", type: "boolean", example: false),
                                new OA\Property(property: "is_active", type: "boolean", example: true),
                                new OA\Property(property: "last_login_at", type: "string", format: "date-time", nullable: true),
                                new OA\Property(property: "created_at", type: "string", format: "date-time"),
                            ]
                        ),
                        new OA\Property(property: "vehicle_type", type: "string", nullable: true, example: "moto"),
                        new OA\Property(property: "license_plate", type: "string", nullable: true, example: "12345-A-6"),
                        new OA\Property(property: "rating", type: "number", format: "float", example: 4.8),
                        new OA\Property(property: "delivery_count", type: "integer", example: 132),
                        new OA\Property(property: "is_available", type: "boolean", example: true),
                        new OA\Property(property: "last_online_at", type: "string", format: "date-time", nullable: true),
                        new OA\Property(property: "current_latitude", type: "number", format: "float", nullable: true),
                        new OA\Property(property: "current_longitude", type: "number", format: "float", nullable: true),
                        new OA\Property(property: "identity_verified", type: "boolean", example: true),
                        new OA\Property(property: "is_approved", type: "boolean", example: true),
                        new OA\Property(property: "is_suspended", type: "boolean", example: false),
                        new OA\Property(property: "created_at", type: "string", format: "date-time"),
                        new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                        new OA\Property(
                            property: "wallet",
                            type: "object",
                            nullable: true,
                            properties: [
                                new OA\Property(property: "delivery_wallet_id", type: "integer", example: 7),
                                new OA\Property(property: "current_balance", type: "number", format: "float", example: 1250.50),
                                new OA\Property(property: "withdrawable_balance", type: "number", format: "float", example: 950.00),
                                new OA\Property(property: "pending_balance", type: "number", format: "float", example: 300.50),
                                new OA\Property(property: "currency_code", type: "string", example: "MAD"),
                                new OA\Property(property: "is_locked", type: "boolean", example: false),
                            ]
                        ),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Profil livreur introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Profil livreur introuvable."),
            ]
        )
    )]
    public function show(int $deliveryProfile): JsonResponse
    {
        if ($deliveryProfile <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de profil livreur invalide.',
            ], 404);
        }

        try {
            $result = $this->deliveryService->getDeliveryProfileById($deliveryProfile);
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
            'data' => $result->toArray(),
        ], 200);
    }
    #[OA\Patch(
        path: "/api/deliveries/profiles/{deliveryProfile}/approve",
        tags: ["Deliveries"],
        summary: "Approuver un livreur",
        description: "Approuve un profil livreur en attente : IsApproved et IdentityVerified passent à 1, IsSuspended repasse à 0.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "deliveryProfile",
        in: "path",
        required: true,
        description: "Identifiant du profil livreur à approuver.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 7
    )]
    #[OA\Response(
        response: 200,
        description: "Livreur approuvé avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Livreur approuvé avec succès."),
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
        description: "Profil introuvable ou déjà approuvé",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Ce livreur est déjà approuvé."),
            ]
        )
    )]
    public function approve(ApproveDeliveryProfileRequest $request, int $deliveryProfile): JsonResponse
    {
        if ($deliveryProfile <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de profil livreur invalide.',
            ], 404);
        }

        $publicId = $request->attributes->get('user_id');
        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable.',
            ], 404);
        }

        $dto = ApproveDeliveryProfileDto::fromArray([
            'DeliveryProfileID' => $deliveryProfile,
            'ApprovedBy'        => $userInfo->userId,
        ]);

        try {
            $this->deliveryService->approveDeliveryProfile($dto);
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
            'message' => 'Livreur approuvé avec succès.',
        ], 200);
    }

    #[OA\Patch(
        path: "/api/deliveries/profiles/{deliveryProfile}/suspend",
        tags: ["Deliveries"],
        summary: "Suspendre un livreur",
        description: "Suspend un profil livreur : IsSuspended passe à 1 et IsAvailable est forcé à 0.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "deliveryProfile",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 7
    )]
    #[OA\RequestBody(
        required: false,
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "Reason", type: "string", nullable: true, maxLength: 500, example: "Plaintes clients répétées."),
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Livreur suspendu avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Livreur suspendu avec succès."),
            ]
        )
    )]
    public function suspend(SuspendDeliveryProfileRequest $request, int $deliveryProfile): JsonResponse
    {
        if ($deliveryProfile <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de profil livreur invalide.',
            ], 404);
        }

        $publicId = $request->attributes->get('user_id');
        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable.',
            ], 404);
        }

        $validated = $request->validated();

        $dto = SuspendDeliveryProfileDto::fromArray([
            'DeliveryProfileID' => $deliveryProfile,
            'SuspendedBy'       => $userInfo->userId,
            'Reason'            => $validated['Reason'] ?? null,
        ]);

        try {
            $this->deliveryService->suspendDeliveryProfile($dto);
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
            'message' => 'Livreur suspendu avec succès.',
        ], 200);
    }
    #[OA\Get(
        path: "/api/deliveries/recommended",
        tags: ["Deliveries"],
        summary: "Lister les livraisons recommandées pour le livreur connecté",
        description: "Retourne les livraisons en attente (non assignées) triées par distance depuis la position actuelle du livreur. Le livreur doit être approuvé, non suspendu et avoir une position GPS enregistrée.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "max_distance_km", in: "query", required: false, schema: new OA\Schema(type: "number", format: "float"), example: 10)]
    #[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
    #[OA\Parameter(name: "per_page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20))]
    #[OA\Response(
        response: 200,
        description: "Livraisons recommandées récupérées avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(
                        properties: [
                            new OA\Property(property: "delivery_id", type: "integer", example: 14),
                            new OA\Property(property: "vendor_profile_id", type: "integer", example: 3),
                            new OA\Property(property: "store_name", type: "string", example: "Boutique Amine"),
                            new OA\Property(property: "delivery_fee", type: "number", format: "float", example: 15.00),
                            new OA\Property(property: "requested_at", type: "string", format: "date-time"),
                            new OA\Property(property: "total_items", type: "integer", example: 2),
                            new OA\Property(property: "distance_km", type: "number", format: "float", example: 3.42),
                        ]
                    )
                ),
                new OA\Property(
                    property: "meta",
                    type: "object",
                    properties: [
                        new OA\Property(property: "total", type: "integer", example: 9),
                        new OA\Property(property: "page", type: "integer", example: 1),
                        new OA\Property(property: "page_size", type: "integer", example: 20),
                        new OA\Property(property: "last_page", type: "integer", example: 1),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Livreur non approuvé, suspendu, ou position GPS manquante",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Position actuelle introuvable. Veuillez activer votre localisation."),
            ]
        )
    )]
    public function recommended(GetRecommendedDeliveriesRequest $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');
        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable.',
            ], 404);
        }

        $deliveryProfile = $this->deliveryService->getDeliveryProfileByUserId($userInfo->userId);

        if (!$deliveryProfile) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur introuvable pour cet utilisateur.',
            ], 404);
        }

        if (!$deliveryProfile->isApproved) {
            return response()->json([
                'success' => false,
                'message' => 'Votre compte n\'est pas encore approuvé.',
            ], 403);
        }

        if ($deliveryProfile->isSuspended) {
            return response()->json([
                'success' => false,
                'message' => 'Votre compte est suspendu.',
            ], 403);
        }

        $dto = GetRecommendedDeliveriesDto::fromRequest($request->validated(), $deliveryProfile->deliveryProfileId);

        try {
            $result = $this->deliveryService->getRecommendedDeliveries($dto);
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
    #[OA\Patch(
    path: "/api/deliveries/location",
    tags: ["Deliveries"],
    summary: "Mettre à jour la position GPS du livreur connecté",
    description: "Met à jour la latitude/longitude actuelles du livreur ainsi que LastOnlineAt. Destiné à être appelé périodiquement par l'application mobile pendant que le livreur est en ligne.",
    security: [["bearerAuth" => []]]
)]
#[OA\RequestBody(
    required: true,
    content: new OA\JsonContent(
        required: ["Latitude", "Longitude"],
        properties: [
            new OA\Property(property: "Latitude", type: "number", format: "float", example: 33.5731),
            new OA\Property(property: "Longitude", type: "number", format: "float", example: -7.5898),
        ]
    )
)]
#[OA\Response(
    response: 200,
    description: "Position mise à jour avec succès",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "success", type: "boolean", example: true),
            new OA\Property(property: "message", type: "string", example: "Position mise à jour avec succès."),
        ]
    )
)]
#[OA\Response(
    response: 404,
    description: "Utilisateur ou profil livreur introuvable",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "success", type: "boolean", example: false),
            new OA\Property(property: "message", type: "string", example: "Profil livreur introuvable pour cet utilisateur."),
        ]
    )
)]
#[OA\Response(
    response: 422,
    description: "Coordonnées invalides",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "success", type: "boolean", example: false),
            new OA\Property(property: "message", type: "string", example: "Latitude invalide."),
        ]
    )
)]
public function updateLocation(UpdateDeliveryLocationRequest $request): JsonResponse
{
    $publicId = $request->attributes->get('user_id');
    $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

    if (!$userInfo) {
        return response()->json([
            'success' => false,
            'message' => 'Utilisateur introuvable.',
        ], 404);
    }

    $deliveryProfile = $this->deliveryService->getDeliveryProfileByUserId($userInfo->userId);

    if (!$deliveryProfile) {
        return response()->json([
            'success' => false,
            'message' => 'Profil livreur introuvable pour cet utilisateur.',
        ], 404);
    }

    $validated = $request->validated();

    $dto = UpdateDeliveryLocationDto::fromArray([
        'DeliveryProfileID' => $deliveryProfile->deliveryProfileId,
        'Latitude'          => $validated['Latitude'],
        'Longitude'         => $validated['Longitude'],
    ]);

    try {
        $this->deliveryService->updateDeliveryLocation($dto);
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
        'message' => 'Position mise à jour avec succès.',
    ], 200);
}
}
