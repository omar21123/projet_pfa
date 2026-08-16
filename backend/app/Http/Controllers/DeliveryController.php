<?php
// app/Http/Controllers/DeliveryController.php

namespace App\Http\Controllers;

use App\DTOs\Delivery\ApproveDeliveryProfileDto;
use App\DTOs\Delivery\CancelDeliveryDto;
use App\DTOs\Delivery\GetAllDeliveryProfilesDto;
use App\DTOs\Delivery\GetDeliveryHistoryDto;
use App\DTOs\Delivery\GetRecommendedDeliveriesDto;
use App\DTOs\Delivery\GetVendorDeliveriesDto;
use App\DTOs\Delivery\RemitCashDto;
use App\DTOs\Delivery\RequestWithdrawDto;
use App\DTOs\Delivery\SuspendDeliveryProfileDto;
use App\DTOs\Delivery\UpdateDeliveryLocationDto;
use App\Http\Requests\Delivery\AcceptDeliveryRequest;
use App\Http\Requests\Delivery\ApproveDeliveryProfileRequest;
use App\Http\Requests\Delivery\CancelDeliveryRequest;
use App\Http\Requests\Delivery\GetAllDeliveryProfilesRequest;
use App\Http\Requests\Delivery\GetDeliveryHistoryRequest;
use App\Http\Requests\Delivery\GetRecommendedDeliveriesRequest;
use App\Http\Requests\Delivery\GetVendorDeliveriesRequest;
use App\Http\Requests\Delivery\MarkDeliveryDeliveredByLivreurRequest;
use App\Http\Requests\Delivery\MarkDeliveryInTransitRequest;
use App\Http\Requests\Delivery\MarkDeliveryPickedUpRequest;
use App\Http\Requests\Delivery\PaginationRequest;
use App\Http\Requests\Delivery\RemitCashRequest;
use App\Http\Requests\Delivery\RequestWithdrawRequest;
use App\Http\Requests\Delivery\SuspendDeliveryProfileRequest;
use App\Http\Requests\Delivery\UpdateDeliveryLocationRequest;
use App\Services\Interface\DeliveryServiceInterface;
use App\Services\UserService;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;
use Symfony\Component\HttpFoundation\Request;

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
    #[OA\Get(
        path: "/api/deliveries/history",
        tags: ["Deliveries"],
        summary: "Historique des livraisons du livreur connecté",
        description: "Retourne la liste paginée de toutes les livraisons jamais assignées au livreur authentifié (tous statuts confondus), triées par date de demande décroissante. Filtrable par statut et plage de dates.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "status", in: "query", required: false, schema: new OA\Schema(type: "string"), example: "delivered")]
    #[OA\Parameter(name: "date_from", in: "query", required: false, schema: new OA\Schema(type: "string", format: "date"))]
    #[OA\Parameter(name: "date_to", in: "query", required: false, schema: new OA\Schema(type: "string", format: "date"))]
    #[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
    #[OA\Parameter(name: "per_page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20))]
    #[OA\Response(
        response: 200,
        description: "Historique récupéré avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(
                        properties: [
                            new OA\Property(property: "delivery_id", type: "integer", example: 14),
                            new OA\Property(property: "order_id", type: "integer", example: 88),
                            new OA\Property(property: "vendor_profile_id", type: "integer", example: 3),
                            new OA\Property(property: "store_name", type: "string", example: "Boutique Amine"),
                            new OA\Property(property: "status_code", type: "string", example: "delivered"),
                            new OA\Property(property: "status_name", type: "string", example: "Livrée"),
                            new OA\Property(property: "delivery_fee", type: "number", format: "float", example: 15.00),
                            new OA\Property(property: "total_items", type: "integer", example: 2),
                            new OA\Property(property: "requested_at", type: "string", format: "date-time"),
                            new OA\Property(property: "delivered_at", type: "string", format: "date-time", nullable: true),
                        ]
                    )
                ),
                new OA\Property(
                    property: "meta",
                    type: "object",
                    properties: [
                        new OA\Property(property: "total", type: "integer", example: 42),
                        new OA\Property(property: "page", type: "integer", example: 1),
                        new OA\Property(property: "page_size", type: "integer", example: 20),
                        new OA\Property(property: "last_page", type: "integer", example: 3),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Profil livreur introuvable"
    )]
    public function history(GetDeliveryHistoryRequest $request): JsonResponse
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

        $dto = GetDeliveryHistoryDto::fromRequest($request->validated(), $deliveryProfile->deliveryProfileId);

        try {
            $result = $this->deliveryService->getDeliveryHistory($dto);
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
        path: "/api/deliveries/{delivery}/accept",
        tags: ["Deliveries"],
        summary: "Accepter une livraison",
        description: "Le livreur connecté accepte une livraison en attente. La livraison passe au statut 'accepted' et lui est assignée. Échoue si déjà acceptée par un autre livreur ou si le compte n'est pas approuvé.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "delivery",
        in: "path",
        required: true,
        description: "Identifiant de la livraison à accepter.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 14
    )]
    #[OA\Response(
        response: 200,
        description: "Livraison acceptée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Livraison acceptée avec succès."),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur, profil livreur ou livraison introuvable"
    )]
    #[OA\Response(
        response: 422,
        description: "Livraison déjà acceptée, compte non approuvé, ou compte suspendu",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Cette livraison a déjà été acceptée par un autre livreur."),
            ]
        )
    )]
    public function accept(AcceptDeliveryRequest $request, int $delivery): JsonResponse
    {
        if ($delivery <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de livraison invalide.',
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

        $deliveryProfile = $this->deliveryService->getDeliveryProfileByUserId($userInfo->userId);

        if (!$deliveryProfile) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur introuvable pour cet utilisateur.',
            ], 404);
        }

        try {
            $this->deliveryService->acceptDeliveryById($delivery, $deliveryProfile->deliveryProfileId);
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
            'message' => 'Livraison acceptée avec succès.',
        ], 200);
    }
    #[OA\Get(
        path: "/api/deliveries/vendor",
        tags: ["Deliveries"],
        summary: "Lister les livraisons du vendeur connecté",
        description: "Retourne la liste paginée des livraisons issues des commandes du vendeur, avec indication si un livreur a déjà pris en charge la livraison. Filtrable par statut et par prise en charge (is_taken).",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "status", in: "query", required: false, schema: new OA\Schema(type: "string"), example: "pending")]
    #[OA\Parameter(name: "is_taken", in: "query", required: false, schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
    #[OA\Parameter(name: "per_page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20))]
    #[OA\Response(
        response: 200,
        description: "Livraisons récupérées avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(
                        properties: [
                            new OA\Property(property: "delivery_id", type: "integer", example: 14),
                            new OA\Property(property: "order_id", type: "integer", example: 88),
                            new OA\Property(property: "status_code", type: "string", example: "pending"),
                            new OA\Property(property: "status_name", type: "string", example: "En attente"),
                            new OA\Property(property: "is_taken", type: "boolean", example: false),
                            new OA\Property(
                                property: "livreur",
                                type: "object",
                                nullable: true,
                                properties: [
                                    new OA\Property(property: "name", type: "string", example: "Youssef El Amrani"),
                                    new OA\Property(property: "phone", type: "string", example: "+212600000000"),
                                ]
                            ),
                            new OA\Property(property: "delivery_fee", type: "number", format: "float", example: 15.00),
                            new OA\Property(property: "total_items", type: "integer", example: 2),
                            new OA\Property(property: "requested_at", type: "string", format: "date-time"),
                        ]
                    )
                ),
                new OA\Property(
                    property: "meta",
                    type: "object",
                    properties: [
                        new OA\Property(property: "total", type: "integer", example: 12),
                        new OA\Property(property: "page", type: "integer", example: 1),
                        new OA\Property(property: "page_size", type: "integer", example: 20),
                        new OA\Property(property: "last_page", type: "integer", example: 1),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(response: 404, description: "Profil vendeur introuvable")]
    public function vendorDeliveries(GetVendorDeliveriesRequest $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');
        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable.',
            ], 404);
        }

        $vendorProfile = $this->vendorService->getVendorProfileByUserId($userInfo->userId);

        if (!$vendorProfile) {
            return response()->json([
                'success' => false,
                'message' => 'Profil vendeur introuvable pour cet utilisateur.',
            ], 404);
        }

        $dto = GetVendorDeliveriesDto::fromRequest($request->validated(), $vendorProfile->vendorProfileId);

        try {
            $result = $this->deliveryService->getVendorDeliveries($dto);
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
        path: "/api/deliveries/{delivery}",
        tags: ["Deliveries"],
        summary: "Détails d'une livraison",
        description: "Retourne les informations complètes d'une livraison : adresses de départ/arrivée, statut, et informations du livreur assigné le cas échéant.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "delivery",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 14
    )]
    #[OA\Response(
        response: 200,
        description: "Livraison récupérée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "data", type: "object"),
            ]
        )
    )]
    #[OA\Response(response: 404, description: "Livraison introuvable")]
    public function showInfos(int $delivery): JsonResponse
    {
        if ($delivery <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de livraison invalide.',
            ], 404);
        }

        try {
            $result = $this->deliveryService->getDeliveryDetails($delivery);
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
        path: "/api/deliveries/{delivery}/pickup",
        tags: ["Deliveries"],
        summary: "Marquer une livraison comme récupérée",
        description: "Le livreur assigné confirme avoir récupéré le(s) colis chez le vendeur. La livraison passe du statut 'accepted' à 'picked_up'.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "delivery",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 14
    )]
    #[OA\Response(
        response: 200,
        description: "Livraison marquée comme récupérée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Livraison marquée comme récupérée avec succès."),
            ]
        )
    )]
    #[OA\Response(response: 404, description: "Utilisateur, profil livreur ou livraison introuvable")]
    #[OA\Response(
        response: 422,
        description: "Livraison non assignée à ce livreur ou statut invalide pour cette transition",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Cette livraison est assignée à un autre livreur."),
            ]
        )
    )]
    public function pickup(MarkDeliveryPickedUpRequest $request, int $delivery): JsonResponse
    {
        if ($delivery <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de livraison invalide.',
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

        $deliveryProfile = $this->deliveryService->getDeliveryProfileByUserId($userInfo->userId);

        if (!$deliveryProfile) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur introuvable pour cet utilisateur.',
            ], 404);
        }

        try {
            $this->deliveryService->markDeliveryPickedUp($delivery, $deliveryProfile->deliveryProfileId);
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
            'message' => 'Livraison marquée comme récupérée avec succès.',
        ], 200);
    }
    #[OA\Patch(
        path: "/api/deliveries/{delivery}/in-transit",
        tags: ["Deliveries"],
        summary: "Marquer une livraison en transit",
        description: "Le livreur assigné confirme qu'il est en route vers l'adresse de livraison. La livraison passe du statut 'picked_up' à 'in_transit'.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "delivery",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 14
    )]
    #[OA\Response(
        response: 200,
        description: "Livraison marquée en transit avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Livraison marquée en transit avec succès."),
            ]
        )
    )]
    #[OA\Response(response: 404, description: "Utilisateur, profil livreur ou livraison introuvable")]
    #[OA\Response(
        response: 422,
        description: "Livraison non assignée à ce livreur ou statut invalide pour cette transition",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Cette livraison doit être au statut \"récupérée\" avant de passer en transit."),
            ]
        )
    )]
    public function inTransit(MarkDeliveryInTransitRequest $request, int $delivery): JsonResponse
    {
        if ($delivery <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de livraison invalide.',
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

        $deliveryProfile = $this->deliveryService->getDeliveryProfileByUserId($userInfo->userId);

        if (!$deliveryProfile) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur introuvable pour cet utilisateur.',
            ], 404);
        }

        try {
            $this->deliveryService->markDeliveryInTransit($delivery, $deliveryProfile->deliveryProfileId);
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
            'message' => 'Livraison marquée en transit avec succès.',
        ], 200);
    }
    #[OA\Patch(
        path: "/api/deliveries/{delivery}/deliver",
        tags: ["Deliveries"],
        summary: "Marquer une livraison comme livrée (livreur)",
        description: "Le livreur assigné confirme avoir livré le colis. La livraison passe au statut 'delivered', ses gains sont crédités, le vendeur est payé (80%, 20% commission plateforme), et si la commande est en paiement à la livraison, l'encaissement est enregistré.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "delivery",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 14
    )]
    #[OA\RequestBody(
        required: false,
        content: new OA\JsonContent(
            properties: [
                new OA\Property(
                    property: "CollectedAmount",
                    type: "number",
                    format: "float",
                    nullable: true,
                    description: "Montant encaissé en espèces. Requis uniquement si la commande est en paiement à la livraison (COD).",
                    example: 250.00
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Livraison marquée comme livrée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Livraison finalisée avec succès."),
            ]
        )
    )]
    #[OA\Response(response: 404, description: "Utilisateur, profil livreur ou livraison introuvable")]
    #[OA\Response(
        response: 422,
        description: "Livraison non assignée à ce livreur, ou statut invalide pour cette transition",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Cette livraison doit être en transit avant d'être marquée comme livrée."),
            ]
        )
    )]
    public function deliver(MarkDeliveryDeliveredByLivreurRequest $request, int $delivery): JsonResponse
    {
        if ($delivery <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de livraison invalide.',
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

        $deliveryProfile = $this->deliveryService->getDeliveryProfileByUserId($userInfo->userId);

        if (!$deliveryProfile) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur introuvable pour cet utilisateur.',
            ], 404);
        }

        $validated = $request->validated();

        try {
            $result = $this->deliveryService->markDeliveryDeliveredByLivreur(
                $delivery,
                $deliveryProfile->deliveryProfileId,
                isset($validated['CollectedAmount']) ? (float) $validated['CollectedAmount'] : null
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

        return response()->json([
            'success' => true,
            'message' => $result->message,
        ], 200);
    }
    #[OA\Patch(
        path: "/api/admin/deliveries/{delivery}/cancel",
        tags: ["Deliveries"],
        summary: "Annuler une livraison en attente (admin)",
        description: "Annule une livraison, uniquement si elle est encore au statut 'pending' (aucun livreur assigné).",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "delivery", in: "path", required: true, schema: new OA\Schema(type: "integer", minimum: 1))]
    #[OA\RequestBody(
        required: false,
        content: new OA\JsonContent(properties: [
            new OA\Property(property: "Reason", type: "string", nullable: true, example: "Aucun livreur disponible dans la zone."),
        ])
    )]
    #[OA\Response(response: 200, description: "Livraison annulée avec succès")]
    #[OA\Response(response: 404, description: "Livraison introuvable")]
    #[OA\Response(response: 422, description: "La livraison n'est plus au statut 'pending'")]
    public function cancel(CancelDeliveryRequest $request, int $delivery): JsonResponse
    {
        if ($delivery <= 0) {
            return response()->json(['success' => false, 'message' => 'Identifiant de livraison invalide.'], 404);
        }

        $publicId = $request->attributes->get('user_id');
        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
        }

        $dto = CancelDeliveryDto::fromRequest($request->validated(), $delivery, $userInfo->userId);

        try {
            $this->deliveryService->cancelDelivery($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 422);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json(['success' => true, 'message' => 'Livraison annulée avec succès.'], 200);
    }

    #[OA\Get(
        path: "/api/admin/livreurs/cash-collections/outstanding",
        tags: ["Deliveries"],
        summary: "Voir l'argent COD détenu par les livreurs non remis (admin)",
        description: "Liste, par livreur, le total encaissé en espèces (COD) qui n'a pas encore été remis à la plateforme.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
    #[OA\Parameter(name: "per_page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20))]
    #[OA\Response(response: 200, description: "Liste récupérée avec succès")]
    public function outstandingCash(PaginationRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $page = (int) ($validated['page'] ?? 1);
        $perPage = (int) ($validated['per_page'] ?? 20);

        try {
            $result = $this->deliveryService->getOutstandingCashByLivreur($page, $perPage);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json($result->toArray(), 200);
    }

    #[OA\Patch(
        path: "/api/admin/livreurs/{deliveryProfile}/remit-cash",
        tags: ["Deliveries"],
        summary: "Encaisser l'argent COD d'un livreur (admin)",
        description: "Marque tout l'encaissement COD en attente d'un livreur comme remis à la plateforme, après vérification du montant physique compté.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "deliveryProfile", in: "path", required: true, schema: new OA\Schema(type: "integer", minimum: 1))]
    #[OA\RequestBody(
        required: false,
        content: new OA\JsonContent(properties: [
            new OA\Property(property: "ExpectedAmount", type: "number", format: "float", nullable: true, example: 850.00),
        ])
    )]
    #[OA\Response(response: 200, description: "Encaissement remis avec succès")]
    #[OA\Response(response: 422, description: "Aucun encaissement en attente, ou montant ne correspond pas")]
    public function remitCash(RemitCashRequest $request, int $deliveryProfile): JsonResponse
    {
        if ($deliveryProfile <= 0) {
            return response()->json(['success' => false, 'message' => 'Identifiant de profil livreur invalide.'], 404);
        }

        $publicId = $request->attributes->get('user_id');
        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
        }

        $validated = $request->validated();
        $dto = new RemitCashDto(
            deliveryProfileId: $deliveryProfile,
            adminUserId: $userInfo->userId,
            expectedAmount: isset($validated['ExpectedAmount']) ? (float) $validated['ExpectedAmount'] : null,
        );

        try {
            $result = $this->deliveryService->remitLivreurCash($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 422);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json(array_merge(['success' => true], $result->toArray()), 200);
    }

    #[OA\Get(
        path: "/api/livreur/wallet",
        tags: ["Deliveries"],
        summary: "Voir mon portefeuille (livreur)",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Response(response: 200, description: "Portefeuille récupéré avec succès")]
    #[OA\Response(response: 404, description: "Portefeuille introuvable")]
    public function myWallet(Request $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');
        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
        }

        $deliveryProfile = $this->deliveryService->getDeliveryProfileByUserId($userInfo->userId);

        if (!$deliveryProfile) {
            return response()->json(['success' => false, 'message' => 'Profil livreur introuvable pour cet utilisateur.'], 404);
        }

        $wallet = $this->deliveryService->getWalletByProfileId($deliveryProfile->deliveryProfileId);

        if (!$wallet) {
            return response()->json(['success' => false, 'message' => 'Portefeuille introuvable.'], 404);
        }

        return response()->json(array_merge(['success' => true], $wallet->toArray()), 200);
    }

    #[OA\Get(
        path: "/api/livreur/wallet/withdrawals",
        tags: ["Deliveries"],
        summary: "Historique de mes retraits (livreur)",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
    #[OA\Parameter(name: "per_page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20))]
    #[OA\Response(response: 200, description: "Historique récupéré avec succès")]
    public function myWithdrawHistory(PaginationRequest $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');
        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
        }

        $deliveryProfile = $this->deliveryService->getDeliveryProfileByUserId($userInfo->userId);

        if (!$deliveryProfile) {
            return response()->json(['success' => false, 'message' => 'Profil livreur introuvable pour cet utilisateur.'], 404);
        }

        $validated = $request->validated();
        $page = (int) ($validated['page'] ?? 1);
        $perPage = (int) ($validated['per_page'] ?? 20);

        $result = $this->deliveryService->getWithdrawHistory($deliveryProfile->deliveryProfileId, $page, $perPage);

        return response()->json($result->toArray(), 200);
    }

    #[OA\Post(
        path: "/api/livreur/wallet/withdraw",
        tags: ["Deliveries"],
        summary: "Demander un retrait (livreur)",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["Amount", "PaymentMethodID"],
            properties: [
                new OA\Property(property: "Amount", type: "number", format: "float", example: 300.00),
                new OA\Property(property: "PaymentMethodID", type: "integer", example: 2),
            ]
        )
    )]
    #[OA\Response(response: 200, description: "Demande de retrait envoyée avec succès")]
    #[OA\Response(response: 422, description: "Solde insuffisant ou portefeuille bloqué")]
    public function requestWithdraw(RequestWithdrawRequest $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');
        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
        }

        $deliveryProfile = $this->deliveryService->getDeliveryProfileByUserId($userInfo->userId);

        if (!$deliveryProfile) {
            return response()->json(['success' => false, 'message' => 'Profil livreur introuvable pour cet utilisateur.'], 404);
        }

        $validated = $request->validated();
        $dto = new RequestWithdrawDto(
            deliveryProfileId: $deliveryProfile->deliveryProfileId,
            amount: (float) $validated['Amount'],
            paymentMethodId: (int) $validated['PaymentMethodID'],
        );

        try {
            $withdrawId = $this->deliveryService->requestWithdraw($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 422);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Demande de retrait envoyée avec succès.',
            'delivery_withdraw_id' => $withdrawId,
        ], 200);
    }

    #[OA\Get(
        path: "/api/livreur/wallet/cash-collections/pending",
        tags: ["Deliveries"],
        summary: "Voir l'argent COD que je dois remettre à l'admin (livreur)",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Response(response: 200, description: "Liste récupérée avec succès")]
    public function myPendingCash(Request $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');
        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
        }

        $deliveryProfile = $this->deliveryService->getDeliveryProfileByUserId($userInfo->userId);

        if (!$deliveryProfile) {
            return response()->json(['success' => false, 'message' => 'Profil livreur introuvable pour cet utilisateur.'], 404);
        }

        $result = $this->deliveryService->getPendingCashForLivreur($deliveryProfile->deliveryProfileId);

        return response()->json(array_merge(['success' => true], $result->toArray()), 200);
    }
}
