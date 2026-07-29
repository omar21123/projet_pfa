<?php

namespace App\Http\Controllers;

use App\DTOs\Promotion\CreatePromotionForCategoryDto;
use App\Services\Interface\PromotionServiceInterface;
use App\Services\Interface\UserServiceInterface;
use App\Services\Interface\VendorServiceInterface;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;
use App\DTOs\Promotion\CreatePromotionForProductDto;
use App\DTOs\Promotion\UpdatePromotionDto;
use App\Http\Requests\Promotion\CreatePromotionForCategoryRequest;
use App\Http\Requests\Promotion\CreatePromotionForProductRequest;
use App\Http\Requests\Promotion\UpdatePromotionRequest;
use App\DTOs\Promotion\DeletePromotionDto;
use Illuminate\Http\Request;
use App\DTOs\Promotion\PromotionIdActionDto;
use App\DTOs\Promotion\GetPromotionsByProductDto;
use App\DTOs\Promotion\GetPromotionsByCategoryDto;


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

    #[OA\Post(
        path: "/api/promotions/product",
        tags: ["Promotions"],
        summary: "Créer une promotion sur un produit",
        description: "Crée une promotion ciblant un produit spécifique. Le produit doit appartenir au vendeur authentifié (VendorID déduit du token JWT). La promotion démarre au statut 'En attente' et nécessite une validation admin avant application.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["ProductID", "Name", "DiscountTypeCode", "DiscountValue", "StartDate", "EndDate"],
            properties: [
                new OA\Property(property: "ProductID", type: "integer", example: 452),
                new OA\Property(property: "Name", type: "string", maxLength: 150, example: "Soldes été -20%"),
                new OA\Property(property: "Description", type: "string", nullable: true, maxLength: 500, example: "Réduction limitée sur les écouteurs sans fil."),
                new OA\Property(property: "PromoCode", type: "string", nullable: true, maxLength: 50, example: "ETE20"),
                new OA\Property(property: "DiscountTypeCode", type: "string", enum: ["PERCENTAGE", "FIXED_AMOUNT"], example: "PERCENTAGE"),
                new OA\Property(property: "DiscountValue", type: "number", format: "float", example: 20.00),
                new OA\Property(property: "MaxDiscountAmount", type: "number", format: "float", nullable: true, example: 50.00),
                new OA\Property(property: "MinOrderAmount", type: "number", format: "float", nullable: true, example: 100.00),
                new OA\Property(property: "UsageLimitTotal", type: "integer", nullable: true, example: 500),
                new OA\Property(property: "UsageLimitPerUser", type: "integer", nullable: true, example: 1),
                new OA\Property(property: "StartDate", type: "string", format: "date-time", example: "2026-08-01 00:00:00"),
                new OA\Property(property: "EndDate", type: "string", format: "date-time", example: "2026-08-31 23:59:59"),
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Promotion créée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Promotion créée avec succès"),
                new OA\Property(property: "data", type: "object"),
            ]
        )
    )]
    #[OA\Response(
        response: 403,
        description: "L'utilisateur n'est pas propriétaire de ce produit",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Accès refusé : vous n'êtes pas propriétaire de ce produit"),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur, profil vendeur ou produit introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Produit introuvable"),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Règle métier violée (code promo dupliqué, montants/dates invalides)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Ce code promo est déjà utilisé"),
            ]
        )
    )]
    public function createForProduct(CreatePromotionForProductRequest $request): JsonResponse
    {
        $publicId = request()->attributes->get('user_id');

        $validated = $request->validated();

        $dto = CreatePromotionForProductDto::fromArray([
            'UserPublicID'      => $publicId,
            'ProductID'         => $validated['ProductID'],
            'Name'              => $validated['Name'],
            'Description'       => $validated['Description'] ?? null,
            'PromoCode'         => $validated['PromoCode'] ?? null,
            'DiscountTypeCode'  => $validated['DiscountTypeCode'],
            'DiscountValue'     => $validated['DiscountValue'],
            'MaxDiscountAmount' => $validated['MaxDiscountAmount'] ?? null,
            'MinOrderAmount'    => $validated['MinOrderAmount'] ?? null,
            'UsageLimitTotal'   => $validated['UsageLimitTotal'] ?? null,
            'UsageLimitPerUser' => $validated['UsageLimitPerUser'] ?? null,
            'StartDate'         => $validated['StartDate'],
            'EndDate'           => $validated['EndDate'],
        ]);

        try {
            $result = $this->promotionService->createForProduct($dto);
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
            'message' => 'Promotion créée avec succès',
            'data' => $result->toArray(),
        ], 201);
    }
    #[OA\Post(
        path: "/api/promotions/category",
        tags: ["Promotions"],
        summary: "Créer une promotion sur une catégorie (Admin)",
        description: "Crée une promotion ciblant toute une catégorie de produits. Réservé aux administrateurs. La promotion est directement validée.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["CategoryID", "Name", "DiscountTypeCode", "DiscountValue", "StartDate", "EndDate"],
            properties: [
                new OA\Property(property: "CategoryID", type: "integer", example: 12),
                new OA\Property(property: "Name", type: "string", maxLength: 150, example: "Promo rentrée -15% Électronique"),
                new OA\Property(property: "Description", type: "string", nullable: true, maxLength: 500),
                new OA\Property(property: "PromoCode", type: "string", nullable: true, maxLength: 50, example: "RENTREE15"),
                new OA\Property(property: "DiscountTypeCode", type: "string", enum: ["PERCENTAGE", "FIXED_AMOUNT"], example: "PERCENTAGE"),
                new OA\Property(property: "DiscountValue", type: "number", format: "float", example: 15.00),
                new OA\Property(property: "MaxDiscountAmount", type: "number", format: "float", nullable: true),
                new OA\Property(property: "MinOrderAmount", type: "number", format: "float", nullable: true),
                new OA\Property(property: "UsageLimitTotal", type: "integer", nullable: true),
                new OA\Property(property: "UsageLimitPerUser", type: "integer", nullable: true),
                new OA\Property(property: "StartDate", type: "string", format: "date-time"),
                new OA\Property(property: "EndDate", type: "string", format: "date-time"),
            ]
        )
    )]
    #[OA\Response(response: 201, description: "Promotion créée avec succès")]
    #[OA\Response(response: 404, description: "Utilisateur ou catégorie introuvable")]
    #[OA\Response(response: 422, description: "Règle métier violée")]
    public function createForCategory(CreatePromotionForCategoryRequest $request): JsonResponse
    {
        $publicId = request()->attributes->get('user_id');

        if (!$publicId) {
            return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
        }

        $validated = $request->validated();

        $dto = CreatePromotionForCategoryDto::fromArray([
            'UserPublicID'      => $publicId,
            'CategoryID'        => $validated['CategoryID'],
            'Name'              => $validated['Name'],
            'Description'       => $validated['Description'] ?? null,
            'PromoCode'         => $validated['PromoCode'] ?? null,
            'DiscountTypeCode'  => $validated['DiscountTypeCode'],
            'DiscountValue'     => $validated['DiscountValue'],
            'MaxDiscountAmount' => $validated['MaxDiscountAmount'] ?? null,
            'MinOrderAmount'    => $validated['MinOrderAmount'] ?? null,
            'UsageLimitTotal'   => $validated['UsageLimitTotal'] ?? null,
            'UsageLimitPerUser' => $validated['UsageLimitPerUser'] ?? null,
            'StartDate'         => $validated['StartDate'],
            'EndDate'           => $validated['EndDate'],
        ]);

        try {
            $result = $this->promotionService->createForCategory($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 422);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Promotion créée avec succès',
            'data' => $result->toArray(),
        ], 201);
    }
    #[OA\Put(
        path: "/api/promotions/{promotion}",
        tags: ["Promotions"],
        summary: "Mettre à jour une promotion",
        description: "Met à jour une promotion existante. Le vendeur propriétaire peut modifier ses promotions produit ; l'administrateur peut modifier les promotions catégorie.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "promotion", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["Name", "DiscountTypeCode", "DiscountValue", "StartDate", "EndDate"],
            properties: [
                new OA\Property(property: "Name", type: "string", maxLength: 150),
                new OA\Property(property: "Description", type: "string", nullable: true, maxLength: 500),
                new OA\Property(property: "PromoCode", type: "string", nullable: true, maxLength: 50),
                new OA\Property(property: "DiscountTypeCode", type: "string", enum: ["PERCENTAGE", "FIXED_AMOUNT"]),
                new OA\Property(property: "DiscountValue", type: "number", format: "float"),
                new OA\Property(property: "MaxDiscountAmount", type: "number", format: "float", nullable: true),
                new OA\Property(property: "MinOrderAmount", type: "number", format: "float", nullable: true),
                new OA\Property(property: "UsageLimitTotal", type: "integer", nullable: true),
                new OA\Property(property: "UsageLimitPerUser", type: "integer", nullable: true),
                new OA\Property(property: "StartDate", type: "string", format: "date-time"),
                new OA\Property(property: "EndDate", type: "string", format: "date-time"),
            ]
        )
    )]
    #[OA\Response(response: 200, description: "Promotion mise à jour avec succès")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Promotion introuvable")]
    #[OA\Response(response: 422, description: "Règle métier violée")]
    public function update(UpdatePromotionRequest $request, int $promotion): JsonResponse
    {
        $publicId = request()->attributes->get('user_id');

        if (!$publicId) {
            return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
        }

        $validated = $request->validated();

        $dto = UpdatePromotionDto::fromArray([
            'UserPublicID'      => $publicId,
            'PromotionID'       => $promotion,
            'Name'              => $validated['Name'],
            'Description'       => $validated['Description'] ?? null,
            'PromoCode'         => $validated['PromoCode'] ?? null,
            'DiscountTypeCode'  => $validated['DiscountTypeCode'],
            'DiscountValue'     => $validated['DiscountValue'],
            'MaxDiscountAmount' => $validated['MaxDiscountAmount'] ?? null,
            'MinOrderAmount'    => $validated['MinOrderAmount'] ?? null,
            'UsageLimitTotal'   => $validated['UsageLimitTotal'] ?? null,
            'UsageLimitPerUser' => $validated['UsageLimitPerUser'] ?? null,
            'StartDate'         => $validated['StartDate'],
            'EndDate'           => $validated['EndDate'],
        ]);

        try {
            $this->promotionService->update($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 422);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Promotion mise à jour avec succès',
        ], 200);
    }


    #[OA\Delete(
        path: "/api/promotions/{promotion}",
        tags: ["Promotions"],
        summary: "Supprimer une promotion (soft delete)",
        description: "Marque une promotion comme supprimée (DeletedAt renseigné) sans effacer la ligne en base. La promotion est également désactivée (IsActive = 0). Réservé au vendeur propriétaire.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "promotion",
        in: "path",
        required: true,
        description: "Identifiant de la promotion à supprimer.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 12
    )]
    #[OA\Response(
        response: 200,
        description: "Promotion supprimée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Promotion supprimée avec succès"),
            ]
        )
    )]
    #[OA\Response(
        response: 403,
        description: "L'utilisateur n'est pas propriétaire de cette promotion",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Accès refusé : vous n'êtes pas propriétaire de cette promotion"),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur, profil vendeur ou promotion introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Promotion introuvable"),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "La promotion est déjà supprimée",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Cette promotion est déjà supprimée"),
            ]
        )
    )]
    public function destroy(Request $request, int $promotion): JsonResponse
    {
        if ($promotion <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de promotion invalide.',
            ], 404);
        }

        $publicId = $request->attributes->get('user_id');

        $dto = DeletePromotionDto::fromArray([
            'UserPublicID' => $publicId,
            'PromotionID'  => $promotion,
        ]);

        try {
            $this->promotionService->softDelete($dto);
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
            'message' => 'Promotion supprimée avec succès',
        ], 200);
    }
    #[OA\Patch(
        path: "/api/promotions/{promotion}/deactivate",
        tags: ["Promotions"],
        summary: "Désactiver une promotion",
        description: "Désactive temporairement une promotion (IsActive = 0) sans la supprimer. La promotion reste visible et peut être réactivée plus tard. Réservé au vendeur propriétaire.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "promotion",
        in: "path",
        required: true,
        description: "Identifiant de la promotion à désactiver.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 12
    )]
    #[OA\Response(
        response: 200,
        description: "Promotion désactivée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Promotion désactivée avec succès"),
            ]
        )
    )]
    #[OA\Response(
        response: 403,
        description: "L'utilisateur n'est pas propriétaire de cette promotion",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Accès refusé : vous n'êtes pas propriétaire de cette promotion"),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur, profil vendeur ou promotion introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Promotion introuvable"),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "La promotion est déjà désactivée ou a été supprimée",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Cette promotion est déjà désactivée"),
            ]
        )
    )]
    public function deactivate(Request $request, int $promotion): JsonResponse
    {
        if ($promotion <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de promotion invalide.',
            ], 404);
        }

        $publicId = $request->attributes->get('user_id');

        $dto = PromotionIdActionDto::fromArray([
            'UserPublicID' => $publicId,
            'PromotionID'  => $promotion,
        ]);

        try {
            $this->promotionService->deactivate($dto);
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
            'message' => 'Promotion désactivée avec succès',
        ], 200);
    }
    #[OA\Get(
        path: "/api/promotions/{promotion}",
        tags: ["Promotions"],
        summary: "Détails d'une promotion",
        description: "Retourne les informations complètes d'une promotion. Les promotions de catégorie sont réservées à l'administrateur. Les promotions produit/catalogue sont consultables par l'admin ou le vendeur propriétaire.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "promotion",
        in: "path",
        required: true,
        description: "Identifiant de la promotion.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 12
    )]
    #[OA\Response(
        response: 200,
        description: "Promotion récupérée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "promotion_id", type: "integer", example: 12),
                        new OA\Property(property: "vendor_id", type: "integer", example: 10),
                        new OA\Property(property: "name", type: "string", example: "Soldes été -20%"),
                        new OA\Property(property: "description", type: "string", nullable: true),
                        new OA\Property(property: "promo_code", type: "string", nullable: true, example: "ETE20"),
                        new OA\Property(
                            property: "discount_type",
                            type: "object",
                            properties: [
                                new OA\Property(property: "code", type: "string", example: "PERCENTAGE"),
                                new OA\Property(property: "label", type: "string", example: "Pourcentage"),
                            ]
                        ),
                        new OA\Property(property: "discount_value", type: "number", format: "float", example: 20.00),
                        new OA\Property(property: "max_discount_amount", type: "number", format: "float", nullable: true),
                        new OA\Property(property: "min_order_amount", type: "number", format: "float", nullable: true),
                        new OA\Property(
                            property: "scope_type",
                            type: "object",
                            properties: [
                                new OA\Property(property: "code", type: "string", example: "PRODUCT"),
                                new OA\Property(property: "label", type: "string", example: "Produit spécifique"),
                            ]
                        ),
                        new OA\Property(property: "target_product_id", type: "integer", nullable: true, example: 452),
                        new OA\Property(property: "target_category_id", type: "integer", nullable: true),
                        new OA\Property(property: "usage_limit_total", type: "integer", nullable: true, example: 500),
                        new OA\Property(property: "usage_limit_per_user", type: "integer", example: 1),
                        new OA\Property(property: "usage_count", type: "integer", example: 47),
                        new OA\Property(property: "start_date", type: "string", format: "date-time"),
                        new OA\Property(property: "end_date", type: "string", format: "date-time"),
                        new OA\Property(
                            property: "status",
                            type: "object",
                            properties: [
                                new OA\Property(property: "code", type: "string", example: "VALIDATED"),
                                new OA\Property(property: "label", type: "string", example: "Validée"),
                            ]
                        ),
                        new OA\Property(property: "is_active", type: "boolean", example: true),
                        new OA\Property(property: "created_at", type: "string", format: "date-time"),
                        new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 403,
        description: "Accès refusé (promotion de catégorie réservée à l'admin, ou non propriétaire)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Accès refusé : vous n'êtes pas propriétaire de cette promotion"),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur, profil vendeur ou promotion introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Promotion introuvable"),
            ]
        )
    )]
    public function show(Request $request, int $promotion): JsonResponse
    {
        if ($promotion <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de promotion invalide.',
            ], 404);
        }

        $publicId = $request->attributes->get('user_id');

        $dto = PromotionIdActionDto::fromArray([
            'UserPublicID' => $publicId,
            'PromotionID'  => $promotion,
        ]);

        try {
            $result = $this->promotionService->getById($dto);
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

    #[OA\Get(
        path: "/api/promotions/product/{product}",
        tags: ["Promotions"],
        summary: "Lister les promotions d'un produit",
        description: "Retourne toutes les promotions actives (non supprimées) ciblant un produit spécifique. Réservé à l'admin ou au vendeur propriétaire du produit.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "product",
        in: "path",
        required: true,
        description: "Identifiant du produit.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 452
    )]
    #[OA\Response(
        response: 200,
        description: "Promotions récupérées avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(type: "object")
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 403,
        description: "L'utilisateur n'est pas propriétaire de ce produit",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Accès refusé : vous n'êtes pas propriétaire de ce produit"),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur ou produit introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Produit introuvable"),
            ]
        )
    )]
    public function getByProduct(Request $request, int $product): JsonResponse
    {
        if ($product <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de produit invalide.',
            ], 404);
        }

        $publicId = $request->attributes->get('user_id');

        $dto = GetPromotionsByProductDto::fromArray([
            'UserPublicID' => $publicId,
            'ProductID'    => $product,
        ]);

        try {
            $result = $this->promotionService->getByProduct($dto);
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
            'data' => array_map(fn($p) => $p->toArray(), $result),
        ], 200);
    }

    #[OA\Get(
        path: "/api/promotions/category/{category}",
        tags: ["Promotions"],
        summary: "Lister les promotions d'une catégorie",
        description: "Retourne toutes les promotions actives (non supprimées) ciblant une catégorie spécifique. Réservé aux administrateurs.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "category",
        in: "path",
        required: true,
        description: "Identifiant de la catégorie.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 10
    )]
    #[OA\Response(
        response: 200,
        description: "Promotions récupérées avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(type: "object")
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 403,
        description: "Accès réservé aux administrateurs",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Accès refusé : seul un administrateur peut consulter les promotions de catégorie"),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur ou catégorie introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Catégorie introuvable"),
            ]
        )
    )]
    public function getByCategory(Request $request, int $category): JsonResponse
    {
        if ($category <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de catégorie invalide.',
            ], 404);
        }

        $publicId = $request->attributes->get('user_id');

        $dto = GetPromotionsByCategoryDto::fromArray([
            'UserPublicID' => $publicId,
            'CategoryID'   => $category,
        ]);

        try {
            $result = $this->promotionService->getByCategory($dto);
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
            'data' => array_map(fn($p) => $p->toArray(), $result),
        ], 200);
    }
}
