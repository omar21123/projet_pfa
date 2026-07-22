<?php

namespace App\Http\Controllers;

use App\DTOs\Product\BlockProductDto;
use App\DTOs\Product\CreateProductDto;
use App\DTOs\Product\GetAllProductsAdminDto;
use App\DTOs\Product\RefuseProductDto;
use App\DTOs\Product\ValidateProductDto;
use App\Http\Requests\Product\BlockProductRequest;
use App\Http\Requests\Product\CreateProductRequest;
use App\Http\Requests\Product\GetAllProductsAdminRequest;
use App\Http\Requests\Product\RefuseProductRequest;
use App\Http\Requests\Product\ValidateProductRequest;
use App\Services\Interface\ProductServiceInterface;
use App\Services\Interface\BrandServiceInterface;
use App\Services\Interface\ProductModelServiceInterface;
use App\Services\Interface\FileUploadServiceInterface;
use App\Services\Interface\UserServiceInterface;
use App\Services\Interface\VendorServiceInterface;
use Illuminate\Http\JsonResponse;
use Illuminate\Foundation\Http\FormRequest;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Products",
    description: "Gestion des produits"
)]
class ProductController extends Controller
{
    public function __construct(
        protected ProductServiceInterface $productService,
        private BrandServiceInterface $brandService,
        private ProductModelServiceInterface $productModelService,
        private FileUploadServiceInterface $fileUploadService,
        private UserServiceInterface $userService,
        private VendorServiceInterface $vendorService,
    ) {}

    #[OA\Post(
        path: "/api/products/create",
        tags: ["Products"],
        summary: "Créer un produit",
        description: "Crée un nouveau produit avec ses ressources (vidéos/images), catégories, attributs de configuration (avec options), tags et modes de paiement autorisés. Le VendorID est résolu automatiquement depuis le token JWT (PublicID -> UserID -> VendorID). Toutes les ressources doivent être envoyées en tant que fichiers via multipart/form-data.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        description: "Données du produit à créer. Envoyé en multipart/form-data car les ressources contiennent des fichiers binaires (vidéos/images). Le VendorID n'est pas à envoyer, il est déduit du token d'authentification.",
        content: new OA\MediaType(
            mediaType: "multipart/form-data",
            schema: new OA\Schema(
                required: [
                    "Name",
                    "Barcode",
                    "BasePrice",
                    "Stock",
                    "Ressource",
                    "Categories",
                    "AllowedPayment"
                ],
                properties: [
                    new OA\Property(
                        property: "BrandID",
                        type: "integer",
                        nullable: true,
                        description: "Identifiant de la marque. Facultatif — validé uniquement s'il est renseigné.",
                        example: 5
                    ),
                    new OA\Property(
                        property: "ModelID",
                        type: "integer",
                        nullable: true,
                        description: "Identifiant du modèle. Facultatif — validé uniquement s'il est renseigné.",
                        example: 124
                    ),
                    new OA\Property(
                        property: "Name",
                        type: "string",
                        maxLength: 255,
                        description: "Nom du produit.",
                        example: "Wireless Bluetooth Headphones Pro"
                    ),
                    new OA\Property(
                        property: "Barcode",
                        type: "string",
                        maxLength: 100,
                        description: "Code-barres unique du produit.",
                        example: "8806090123456"
                    ),
                    new OA\Property(
                        property: "Description",
                        type: "string",
                        nullable: true,
                        description: "Description détaillée du produit.",
                        example: "High-fidelity over-ear headphones with active noise cancellation and 40-hour battery life."
                    ),
                    new OA\Property(
                        property: "BasePrice",
                        type: "number",
                        format: "float",
                        minimum: 0,
                        description: "Prix de base du produit (hors options).",
                        example: 149.99
                    ),
                    new OA\Property(
                        property: "Stock",
                        type: "integer",
                        minimum: 0,
                        description: "Quantité en stock.",
                        example: 250
                    ),
                    new OA\Property(
                        property: "Ressource",
                        type: "array",
                        description: "Liste des ressources média du produit (vidéos, images). Chaque élément doit contenir un fichier binaire.",
                        items: new OA\Items(
                            properties: [
                                new OA\Property(
                                    property: "type",
                                    type: "string",
                                    enum: ["video", "Video", "image", "Image"],
                                    description: "Type de la ressource.",
                                    example: "video"
                                ),
                                new OA\Property(
                                    property: "Role",
                                    type: "integer",
                                    description: "Rôle de la ressource (ex: 1 = principale, 2 = miniature). Doit exister dans ResourcesRoles.",
                                    example: 1
                                ),
                                new OA\Property(
                                    property: "file",
                                    type: "string",
                                    format: "binary",
                                    description: "Fichier binaire (vidéo ou image, max 50MB)."
                                ),
                            ]
                        )
                    ),
                    new OA\Property(
                        property: "Categories",
                        type: "array",
                        description: "Liste des identifiants de catégories associées au produit.",
                        items: new OA\Items(type: "integer"),
                        example: [10, 5, 100]
                    ),
                    new OA\Property(
                        property: "Attribute",
                        type: "array",
                        description: "Liste des attributs de configuration du produit (ex: Couleur, Taille), chacun avec ses options possibles.",
                        items: new OA\Items(
                            properties: [
                                new OA\Property(
                                    property: "ConfigName",
                                    type: "string",
                                    maxLength: 150,
                                    description: "Nom de l'attribut de configuration.",
                                    example: "Color"
                                ),
                                new OA\Property(
                                    property: "ConfigOptions",
                                    type: "array",
                                    description: "Options disponibles pour cet attribut.",
                                    items: new OA\Items(
                                        properties: [
                                            new OA\Property(
                                                property: "Name",
                                                type: "string",
                                                maxLength: 150,
                                                description: "Nom/valeur de l'option.",
                                                example: "Red"
                                            ),
                                            new OA\Property(
                                                property: "IsDefault",
                                                type: "boolean",
                                                description: "Indique si cette option est la valeur par défaut pour l'attribut.",
                                                example: true
                                            ),
                                        ]
                                    )
                                ),
                            ]
                        )
                    ),
                    new OA\Property(
                        property: "Tags",
                        type: "array",
                        description: "Liste de tags libres associés au produit (utilisés pour la recherche).",
                        items: new OA\Items(type: "string"),
                        example: ["clothes", "T-Shirt", "all Sized"]
                    ),
                    new OA\Property(
                        property: "AllowedPayment",
                        type: "array",
                        description: "Liste des identifiants de modes de paiement autorisés pour ce produit.",
                        items: new OA\Items(type: "integer"),
                        example: [1, 2]
                    ),
                ]
            )
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Produit créé avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Produit créé avec succès"),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "ID", type: "integer", example: 452),
                        new OA\Property(property: "VendorID", type: "integer", example: 10),
                        new OA\Property(property: "BrandID", type: "integer", nullable: true, example: 5),
                        new OA\Property(property: "ModelID", type: "integer", nullable: true, example: 124),
                        new OA\Property(property: "Name", type: "string", example: "Wireless Bluetooth Headphones Pro"),
                        new OA\Property(property: "Barcode", type: "string", example: "8806090123456"),
                        new OA\Property(property: "Description", type: "string", nullable: true),
                        new OA\Property(property: "BasePrice", type: "number", format: "float", example: 149.99),
                        new OA\Property(property: "Stock", type: "integer", example: 250),
                        new OA\Property(property: "Status", type: "integer", example: 1),
                        new OA\Property(property: "IsActive", type: "boolean", example: true),
                        new OA\Property(property: "CreatedAt", type: "string", format: "date-time"),
                        new OA\Property(property: "UpdatedAt", type: "string", format: "date-time"),
                    ]
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
        response: 403,
        description: "Accès refusé",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Accès refusé."),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur ou profil vendeur introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Profil vendeur introuvable pour cet utilisateur."),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Règle métier violée (marque/modèle introuvable, code-barres déjà utilisé, catégorie/rôle/type de ressource invalide, etc.)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Ce code-barres est déjà utilisé par un autre produit."),
            ]
        )
    )]
    public function store(CreateProductRequest $request): JsonResponse
    {
        $validated = $request->validated();

        // PublicID récupéré depuis le middleware JWT
        $publicId = $request->attributes->get('user_id');

        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable.'
            ], 404);
        }

        $vendorProfile = $this->vendorService->getVendorProfileByUserId($userInfo->userId);

        if (!$vendorProfile) {
            return response()->json([
                'success' => false,
                'message' => 'Profil vendeur introuvable pour cet utilisateur.'
            ], 404);
        }
        if (!$vendorProfile->isApproved) {
            return response()->json([
                'success' => false,
                'message' => 'Votre profil vendeur n\'est pas encore approuvé.'
            ], 403);
        }

        if ($vendorProfile->isSuspended) {
            return response()->json([
                'success' => false,
                'message' => 'Votre profil vendeur est suspendu.'
            ], 403);
        }

        if ($vendorProfile->verificationStatus !== 1) {
            return response()->json([
                'success' => false,
                'message' => 'Votre profil vendeur n\'est pas vérifié.'
            ], 403);
        }
        $validated['VendorID'] = $vendorProfile->vendorProfileId;

        if (!empty($validated['BrandID'])) {
            if (!$this->brandService->existsById($validated['BrandID'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'La marque spécifiée n\'existe pas.'
                ], 422);
            }
        }

        if (!empty($validated['ModelID'])) {
            if (!$this->productModelService->existsById($validated['ModelID'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Le modèle spécifié n\'existe pas.'
                ], 422);
            }
        }

        $resourceInputs = $request->input('Ressource', []);
        $resources = [];
        foreach ($request->file('Ressource', []) as $index => $fileGroup) {
            $storedPath = $this->fileUploadService->storeAvatar($fileGroup['file']);
            $resourceMeta = $resourceInputs[$index] ?? $validated['Ressource'][$index] ?? [];

            $resources[] = [
                'type' => $resourceMeta['type'] ?? null,
                'Role' => $resourceMeta['Role'] ?? null,
                'Path' => $storedPath,
            ];
        }
        $validated['Ressource'] = $resources;

        $dto = CreateProductDto::fromArray($validated);

        try {
            $product = $this->productService->createProduct($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Produit créé avec succès',
            'data' => $product
        ], 201);
    }
    #[OA\Get(
        path: "/api/products/admin",
        tags: ["Products"],
        summary: "Lister les produits (admin)",
        description: "Retourne la liste paginée des produits avec informations vendeur, marque, modèle, statut, et historique de validation/refus/blocage. Filtrable par statut, vendeur, marque, modèle, recherche texte, actif/bloqué et plage de dates.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "status", in: "query", required: false, schema: new OA\Schema(type: "integer"), example: 1)]
    #[OA\Parameter(name: "vendor_id", in: "query", required: false, schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "brand_id", in: "query", required: false, schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "model_id", in: "query", required: false, schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "search", in: "query", required: false, schema: new OA\Schema(type: "string"), example: "headphones")]
    #[OA\Parameter(name: "is_active", in: "query", required: false, schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "is_blocked", in: "query", required: false, schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "date_from", in: "query", required: false, schema: new OA\Schema(type: "string", format: "date"))]
    #[OA\Parameter(name: "date_to", in: "query", required: false, schema: new OA\Schema(type: "string", format: "date"))]
    #[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
    #[OA\Parameter(name: "per_page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20))]
    #[OA\Response(
        response: 200,
        description: "Liste des produits récupérée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "data", type: "array", items: new OA\Items(type: "object")),
                new OA\Property(
                    property: "meta",
                    type: "object",
                    properties: [
                        new OA\Property(property: "total", type: "integer", example: 128),
                        new OA\Property(property: "page", type: "integer", example: 1),
                        new OA\Property(property: "page_size", type: "integer", example: 20),
                        new OA\Property(property: "last_page", type: "integer", example: 7),
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
    public function index(GetAllProductsAdminRequest $request): JsonResponse
    {
        $dto = GetAllProductsAdminDto::fromRequest($request->validated());

        try {
            $result = $this->productService->getAllProductsAdmin($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        return response()->json($result->toArray(), 200);
    }
    #[OA\Get(
        path: "/api/products/{product}",
        tags: ["Products"],
        summary: "Détails d'un produit",
        description: "Retourne les détails complets d'un produit : informations générales, statut, historique de validation/refus/blocage, tags, moyens de paiement autorisés, catégories et attributs de configuration (avec leurs options).",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "product",
        in: "path",
        required: true,
        description: "Identifiant du produit.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 1
    )]
    #[OA\Response(
        response: 200,
        description: "Détails du produit récupérés avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(
                            property: "details",
                            type: "object",
                            properties: [
                                new OA\Property(property: "product_id", type: "integer", example: 1),
                                new OA\Property(property: "product_name", type: "string", example: "Wireless Bluetooth Headphones Pro"),
                                new OA\Property(property: "full_name", type: "string", example: "Jean Dupont"),
                                new OA\Property(property: "brand_name", type: "string", nullable: true, example: "Sony"),
                                new OA\Property(property: "brand_logo", type: "string", nullable: true, example: "https://cdn.example.com/brands/sony.png"),
                                new OA\Property(property: "model_name", type: "string", nullable: true, example: "WH-1000XM5"),
                                new OA\Property(property: "status", type: "string", example: "En attente de validation"),
                                new OA\Property(property: "barcode", type: "string", example: "8806090123456"),
                                new OA\Property(property: "stock", type: "integer", example: 250),
                                new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                new OA\Property(property: "refuse_attempt", type: "integer", nullable: true, example: 0),
                                new OA\Property(property: "refuse_notes", type: "string", nullable: true),
                                new OA\Property(property: "refused_by", type: "string", nullable: true),
                                new OA\Property(property: "refuse_at", type: "string", format: "date-time", nullable: true),
                                new OA\Property(property: "validator_by", type: "string", nullable: true),
                                new OA\Property(property: "validation_notes", type: "string", nullable: true),
                                new OA\Property(property: "validation_date", type: "string", format: "date-time", nullable: true),
                                new OA\Property(property: "is_active", type: "boolean", example: true),
                                new OA\Property(property: "deleted_at", type: "string", format: "date-time", nullable: true),
                                new OA\Property(property: "is_blocked", type: "boolean", example: false),
                                new OA\Property(property: "blocked_date", type: "string", format: "date-time", nullable: true),
                                new OA\Property(property: "blocked_notes", type: "string", nullable: true),
                            ]
                        ),
                        new OA\Property(
                            property: "tags",
                            type: "array",
                            items: new OA\Items(type: "string"),
                            example: ["clothes", "T-Shirt"]
                        ),
                        new OA\Property(
                            property: "allowed_payments",
                            type: "array",
                            items: new OA\Items(
                                properties: [
                                    new OA\Property(property: "name", type: "string", example: "Carte bancaire"),
                                    new OA\Property(property: "code", type: "string", example: "CB"),
                                    new OA\Property(property: "icon_url", type: "string", nullable: true),
                                ]
                            )
                        ),
                        new OA\Property(
                            property: "categories",
                            type: "array",
                            items: new OA\Items(
                                properties: [
                                    new OA\Property(property: "name", type: "string", example: "Électronique"),
                                    new OA\Property(property: "icon_url", type: "string", nullable: true),
                                    new OA\Property(property: "is_primary", type: "boolean", example: true),
                                ]
                            )
                        ),
                        new OA\Property(
                            property: "configs",
                            type: "array",
                            items: new OA\Items(
                                properties: [
                                    new OA\Property(property: "attribute", type: "string", example: "Color"),
                                    new OA\Property(property: "option", type: "string", example: "Red"),
                                    new OA\Property(property: "is_default", type: "boolean", example: true),
                                ]
                            )
                        ),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Produit introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Produit introuvable."),
            ]
        )
    )]
    #[OA\Response(
        response: 500,
        description: "Erreur interne du serveur",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string"),
            ]
        )
    )]
    public function show(int $product): JsonResponse
    {
        if ($product <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de produit invalide.',
            ], 404);
        }

        $isExist = $this->productService->isExistsByID($product);

        if (!$isExist) {
            return response()->json([
                'success' => false,
                'message' => 'Produit introuvable.',
            ], 404);
        }

        try {
            $result = $this->productService->getProductDetails($product);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 404);
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
        path: "/api/products/{product}/validate",
        tags: ["Products"],
        summary: "Valider un produit",
        description: "Valide un produit en attente : met à jour son statut (Status = 2), enregistre l'administrateur validateur, la date de validation et d'éventuelles notes.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "product",
        in: "path",
        required: true,
        description: "Identifiant du produit à valider.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 1
    )]
    #[OA\RequestBody(
        required: false,
        content: new OA\JsonContent(
            properties: [
                new OA\Property(
                    property: "ValidationNotes",
                    type: "string",
                    nullable: true,
                    maxLength: 1000,
                    description: "Notes de l'administrateur concernant la validation.",
                    example: "Produit conforme, images vérifiées."
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Produit validé avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Produit validé avec succès."),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Produit introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Produit introuvable."),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Règle métier violée (produit déjà validé, etc.)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Ce produit est déjà validé."),
            ]
        )
    )]
    public function validateProduct(ValidateProductRequest $request, int $product): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');

        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable.',
            ], 404);
        }

        $validated = $request->validated();

        $dto = ValidateProductDto::fromArray([
            'ProductID'       => $product,
            'ValidatorID'     => $userInfo->userId,
            'ValidationNotes' => $validated['ValidationNotes'] ?? null,
        ]);

        try {
            $this->productService->validateProduct($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Produit validé avec succès.',
        ], 200);
    }
    #[OA\Patch(
        path: "/api/products/{product}/block",
        tags: ["Products"],
        summary: "Bloquer un produit",
        description: "Bloque un produit : met à jour son statut (Status = 4, IsBlocked = 1), enregistre l'administrateur ayant bloqué le produit, la date de blocage et le motif.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "product",
        in: "path",
        required: true,
        description: "Identifiant du produit à bloquer.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 1
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["BlockedNotes"],
            properties: [
                new OA\Property(
                    property: "BlockedNotes",
                    type: "string",
                    maxLength: 1000,
                    description: "Motif du blocage du produit.",
                    example: "Signalement pour contenu non conforme."
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Produit bloqué avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Produit bloqué avec succès."),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Produit introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Produit introuvable."),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Règle métier violée (produit déjà bloqué, motif manquant, etc.)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Ce produit est déjà bloqué."),
            ]
        )
    )]
    public function blockProduct(BlockProductRequest $request, int $product): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');

        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable.',
            ], 404);
        }

        $validated = $request->validated();

        $dto = BlockProductDto::fromArray([
            'ProductID'    => $product,
            'BlockedBy'    => $userInfo->userId,
            'BlockedNotes' => $validated['BlockedNotes'],
        ]);

        try {
            $this->productService->blockProduct($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Produit bloqué avec succès.',
        ], 200);
    }
    #[OA\Patch(
        path: "/api/products/{product}/refuse",
        tags: ["Products"],
        summary: "Refuser un produit",
        description: "Refuse un produit et incrémente son compteur de refus. Après 4 refus consécutifs (3 tentatives précédentes + celle-ci), le produit est automatiquement bloqué via SP_BlockProduct.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "product",
        in: "path",
        required: true,
        description: "Identifiant du produit à refuser.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 1
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["RefuseNotes"],
            properties: [
                new OA\Property(
                    property: "RefuseNotes",
                    type: "string",
                    maxLength: 1000,
                    description: "Motif du refus du produit.",
                    example: "Photos insuffisantes, merci de compléter la fiche produit."
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Produit refusé (ou automatiquement bloqué après le seuil de refus atteint)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Produit refusé."),
                new OA\Property(property: "auto_blocked", type: "boolean", example: false),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Produit introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Produit introuvable."),
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
    public function refuseProduct(RefuseProductRequest $request, int $product): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');

        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable.',
            ], 404);
        }

        $validated = $request->validated();

        $dto = RefuseProductDto::fromArray([
            'ProductID'   => $product,
            'RefusedBy'   => $userInfo->userId,
            'RefuseNotes' => $validated['RefuseNotes'],
        ]);

        try {
            $result = $this->productService->refuseProduct($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'success'      => true,
            'message'      => $result->message,
            'auto_blocked' => $result->autoBlocked,
        ], 200);
    }
}
