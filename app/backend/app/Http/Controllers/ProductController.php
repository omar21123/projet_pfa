<?php

namespace App\Http\Controllers;

use App\DTOs\Product\BlockProductDto;
use App\DTOs\Product\CreateProductDto;
use App\DTOs\Product\GetAllProductsAdminDto;
use App\DTOs\Product\GetProductInfoDto;
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
use App\DTOs\Product\UpdateProductCombinationDto;
use App\Http\Requests\Product\UpdateProductCombinationRequest;
use App\DTOs\Product\vendor\GetVendorProductsDto;
use App\Http\Requests\Product\GetProductInfoRequest;
use App\Http\Requests\Product\GetVendorProductsRequest;
use Symfony\Component\HttpFoundation\Request;

// ...


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
        path: "/api/products",
        tags: ["Products"],
        summary: "Créer un nouveau produit",
        description: "Crée un nouveau produit avec ses ressources, catégories, attributs de configuration, combinaisons (variantes) et tags. Le fournisseur doit être approuvé, non suspendu et vérifié. VendorID est déduit du token JWT.",
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
                        property: "Combinations",
                        type: "array",
                        description: "Liste des combinaisons d'options (variantes) du produit. Chaque combinaison référence des attributs/options déjà déclarés dans 'Attribute'.",
                        items: new OA\Items(
                            properties: [
                                new OA\Property(
                                    property: "SKU",
                                    type: "string",
                                    maxLength: 64,
                                    nullable: true,
                                    description: "Référence unique de la variante.",
                                    example: "TSH-501-RED-M"
                                ),
                                new OA\Property(
                                    property: "Price",
                                    type: "number",
                                    format: "float",
                                    minimum: 0,
                                    description: "Prix de cette combinaison.",
                                    example: 149.00
                                ),
                                new OA\Property(
                                    property: "CompareAtPrice",
                                    type: "number",
                                    format: "float",
                                    nullable: true,
                                    description: "Prix barré (promo), facultatif.",
                                    example: 179.00
                                ),
                                new OA\Property(
                                    property: "Stock",
                                    type: "integer",
                                    minimum: 0,
                                    description: "Stock disponible pour cette combinaison.",
                                    example: 20
                                ),
                                new OA\Property(
                                    property: "IsDefault",
                                    type: "boolean",
                                    description: "Indique si cette combinaison est la variante par défaut du produit.",
                                    example: true
                                ),
                                new OA\Property(
                                    property: "Image",
                                    type: "string",
                                    format: "binary",
                                    nullable: true,
                                    description: "Image spécifique à cette combinaison (optionnelle)."
                                ),
                                new OA\Property(
                                    property: "Options",
                                    type: "array",
                                    description: "Options qui composent cette combinaison. ConfigName/OptionName doivent correspondre à un attribut déclaré dans 'Attribute'.",
                                    items: new OA\Items(
                                        properties: [
                                            new OA\Property(
                                                property: "ConfigName",
                                                type: "string",
                                                maxLength: 150,
                                                example: "Color"
                                            ),
                                            new OA\Property(
                                                property: "OptionName",
                                                type: "string",
                                                maxLength: 150,
                                                example: "Red"
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
        description: "Règle métier violée (marque/modèle introuvable, code-barres déjà utilisé, catégorie/rôle/type de ressource invalide, combinaison invalide ou dupliquée, etc.)",
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
        $validated['VendorID'] = $userInfo->userId;
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

        // ---- Product resources (images/videos) ----
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

        // ---- Combination images (variant-specific images) ----
        $combinationInputs = $validated['Combinations'] ?? [];
        $combinations = [];
        foreach ($combinationInputs as $index => $combo) {
            $imagePath = null;
            if ($request->hasFile("Combinations.$index.Image")) {
                $imagePath = $this->fileUploadService->storeAvatar($request->file("Combinations.$index.Image"));
            }

            $combinations[] = array_merge($combo, ['ImagePath' => $imagePath]);
        }
        $validated['Combinations'] = $combinations;

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
    #[OA\Get(
        path: "/api/products/{product}/combinations",
        tags: ["Products"],
        summary: "Lister les combinaisons (variantes) d'un produit",
        description: "Retourne toutes les combinaisons actives d'un produit avec leur SKU, prix, stock et options (ex: Couleur=Rouge, Taille=M). Réservé au vendeur propriétaire du produit — l'appartenance est vérifiée via le token JWT.",
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
        description: "Combinaisons récupérées avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(
                        properties: [
                            new OA\Property(property: "combination_id", type: "integer", example: 12),
                            new OA\Property(property: "sku", type: "string", nullable: true, example: "TSH-501-RED-M"),
                            new OA\Property(property: "price", type: "number", format: "float", example: 149.00),
                            new OA\Property(property: "stock", type: "integer", example: 20),
                            new OA\Property(property: "image_path", type: "string", nullable: true),
                            new OA\Property(property: "is_default", type: "boolean", example: true),
                            new OA\Property(
                                property: "options",
                                type: "array",
                                items: new OA\Items(
                                    properties: [
                                        new OA\Property(property: "config_name", type: "string", example: "Color"),
                                        new OA\Property(property: "option_name", type: "string", example: "Red"),
                                        new OA\Property(property: "option_value", type: "string", example: "Red"),
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
        description: "Utilisateur ou profil vendeur introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Profil vendeur introuvable pour cet utilisateur"),
            ]
        )
    )]
    public function getCombinations(int $product): JsonResponse
    {
        if ($product <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de produit invalide.',
            ], 404);
        }

        $publicId = request()->attributes->get('user_id');

        try {
            $combinations = $this->productService->getProductCombinationsForVendor($publicId, $product);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        } catch (\Illuminate\Database\QueryException $e) {
            // La SP lève des SIGNAL SQLSTATE '45000' pour les cas métier
            // (utilisateur introuvable, profil vendeur introuvable, non-propriétaire).
            // On extrait le message métier du driver PDO plutôt que de renvoyer une 500 brute.
            $message = $this->extractSignalMessage($e->getMessage());
            $status  = str_contains($message, 'Accès refusé') ? 403 : 404;

            return response()->json([
                'success' => false,
                'message' => $message,
            ], $status);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'data' => array_map(fn($dto) => [
                'combination_id' => $dto->combinationId,
                'sku'            => $dto->sku,
                'price'          => $dto->price,
                'stock'          => $dto->stock,
                'image_path'     => $dto->imagePath,
                'is_default'     => $dto->isDefault,
                'options'        => array_map(fn($opt) => [
                    'config_name'  => $opt->configName,
                    'option_name'  => $opt->optionName,
                    'option_value' => $opt->optionValue,
                ], $dto->options),
            ], $combinations),
        ], 200);
    }

    /**
     * Extrait le message métier d'une exception SIGNAL SQLSTATE '45000'
     * levée par MySQL. Le driver renvoie un message du type :
     * "SQLSTATE[45000]: <<Unknown error>>: 1644 Accès refusé : ..."
     */
    private function extractSignalMessage(string $driverMessage): string
    {
        if (preg_match('/1644\s+(.+?)(\s*\(SQL:|$)/s', $driverMessage, $matches)) {
            return trim($matches[1]);
        }

        return 'Une erreur est survenue lors de la récupération des combinaisons.';
    }




    #[OA\Get(
        path: "/api/products/combinations/{combination}",
        tags: ["Products"],
        summary: "Détails d'une combinaison (variante)",
        description: "Retourne les informations complètes d'une combinaison ainsi que ses options. Réservé au vendeur propriétaire du produit associé.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "combination",
        in: "path",
        required: true,
        description: "Identifiant de la combinaison.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 12
    )]
    #[OA\Response(
        response: 200,
        description: "Combinaison récupérée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "combination_id", type: "integer", example: 12),
                        new OA\Property(property: "product_id", type: "integer", example: 452),
                        new OA\Property(property: "sku", type: "string", nullable: true, example: "TSH-501-RED-M"),
                        new OA\Property(property: "price", type: "number", format: "float", example: 149.00),
                        new OA\Property(property: "compare_at_price", type: "number", format: "float", nullable: true, example: 179.00),
                        new OA\Property(property: "stock", type: "integer", example: 20),
                        new OA\Property(property: "image_path", type: "string", nullable: true),
                        new OA\Property(property: "is_default", type: "boolean", example: true),
                        new OA\Property(property: "is_active", type: "boolean", example: true),
                        new OA\Property(property: "created_at", type: "string", format: "date-time"),
                        new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                        new OA\Property(
                            property: "options",
                            type: "array",
                            items: new OA\Items(
                                properties: [
                                    new OA\Property(property: "config_name", type: "string", example: "Color"),
                                    new OA\Property(property: "option_name", type: "string", example: "Red"),
                                    new OA\Property(property: "option_value", type: "string", example: "Red"),
                                ]
                            )
                        ),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 403,
        description: "L'utilisateur n'est pas propriétaire de cette combinaison",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Accès refusé : vous n'êtes pas propriétaire de cette combinaison"),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur, profil vendeur ou combinaison introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Combinaison introuvable"),
            ]
        )
    )]
    public function showCombination(int $combination): JsonResponse
    {
        if ($combination <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de combinaison invalide.',
            ], 404);
        }

        $publicId = request()->attributes->get('user_id');

        try {
            $result = $this->productService->getCombinationById($publicId, $combination);
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

    #[OA\Put(
        path: "/api/products/combinations/{combination}",
        tags: ["Products"],
        summary: "Mettre à jour une combinaison (variante)",
        description: "Met à jour le SKU, le prix, le prix barré, le stock, l'image et les indicateurs par défaut/actif d'une combinaison. Réservé au vendeur propriétaire. Si IsDefault=true, toute autre combinaison par défaut du même produit est automatiquement désactivée.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "combination",
        in: "path",
        required: true,
        description: "Identifiant de la combinaison à mettre à jour.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 12
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\MediaType(
            mediaType: "multipart/form-data",
            schema: new OA\Schema(
                required: ["Price", "Stock"],
                properties: [
                    new OA\Property(property: "SKU", type: "string", maxLength: 64, nullable: true, example: "TSH-501-RED-M"),
                    new OA\Property(property: "Price", type: "number", format: "float", minimum: 0, example: 149.00),
                    new OA\Property(property: "CompareAtPrice", type: "number", format: "float", nullable: true, minimum: 0, example: 179.00),
                    new OA\Property(property: "Stock", type: "integer", minimum: 0, example: 20),
                    new OA\Property(property: "Image", type: "string", format: "binary", nullable: true, description: "Nouvelle image de la combinaison (optionnelle)."),
                    new OA\Property(property: "IsDefault", type: "boolean", example: true),
                    new OA\Property(property: "IsActive", type: "boolean", example: true),
                ]
            )
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Combinaison mise à jour avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Combinaison mise à jour avec succès"),
                new OA\Property(property: "data", type: "object"),
            ]
        )
    )]
    #[OA\Response(
        response: 403,
        description: "L'utilisateur n'est pas propriétaire de cette combinaison",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Accès refusé : vous n'êtes pas propriétaire de cette combinaison"),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur, profil vendeur ou combinaison introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Combinaison introuvable"),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Règle métier violée (SKU dupliqué, prix/stock invalide, prix barré < prix)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Ce SKU est déjà utilisé par une autre combinaison de ce produit"),
            ]
        )
    )]
    public function updateCombination(UpdateProductCombinationRequest $request, int $combination): JsonResponse
    {
        if ($combination <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de combinaison invalide.',
            ], 404);
        }

        $publicId = request()->attributes->get('user_id');
        $validated = $request->validated();

        $imagePath = null;
        if ($request->hasFile('Image')) {
            $imagePath = $this->fileUploadService->storeAvatar($request->file('Image'));
        }

        $dto = UpdateProductCombinationDto::fromArray([
            'UserPublicID'   => $publicId,
            'CombinationID'  => $combination,
            'SKU'            => $validated['SKU'] ?? null,
            'Price'          => $validated['Price'],
            'CompareAtPrice' => $validated['CompareAtPrice'] ?? null,
            'Stock'          => $validated['Stock'],
            'ImagePath'      => $imagePath,
            'IsDefault'      => $validated['IsDefault'] ?? false,
            'IsActive'       => $validated['IsActive'] ?? true,
        ]);

        try {
            $result = $this->productService->updateCombination($dto);
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
            'message' => 'Combinaison mise à jour avec succès',
            'data' => $result->toArray(),
        ], 200);
    }


    #[OA\Get(
        path: "/api/products/vendor/me",
        tags: ["Products"],
        summary: "Lister les produits du vendeur connecté",
        description: "Retourne la liste paginée de tous les produits créés par le vendeur authentifié via JWT. Filtrable par statut, recherche (nom/code-barres), actif et bloqué.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "status", in: "query", required: false, schema: new OA\Schema(type: "integer"), example: 1)]
    #[OA\Parameter(name: "search", in: "query", required: false, schema: new OA\Schema(type: "string"), example: "Earphones")]
    #[OA\Parameter(name: "is_active", in: "query", required: false, schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "is_blocked", in: "query", required: false, schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
    #[OA\Parameter(name: "per_page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20))]
    #[OA\Response(
        response: 200,
        description: "Liste des produits du vendeur récupérée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(
                        properties: [
                            new OA\Property(property: "product_id", type: "integer", example: 45),
                            new OA\Property(property: "name", type: "string", example: "Wireless Bluetooth Headphones"),
                            new OA\Property(property: "barcode", type: "string", example: "8806090123456"),
                            new OA\Property(property: "base_price", type: "number", format: "float", example: 120.00),
                            new OA\Property(property: "stock", type: "integer", example: 50),
                            new OA\Property(property: "status", type: "integer", example: 1),
                            new OA\Property(property: "status_label", type: "string", example: "En attente"),
                            new OA\Property(property: "is_active", type: "boolean", example: true),
                            new OA\Property(property: "is_blocked", type: "boolean", example: false),
                            new OA\Property(property: "brand_name", type: "string", nullable: true, example: "Sony"),
                            new OA\Property(property: "model_name", type: "string", nullable: true, example: "WH-1000XM5"),
                            new OA\Property(property: "main_image", type: "string", nullable: true, example: "/uploads/avatars/img.jpg"),
                            new OA\Property(property: "created_at", type: "string", format: "date-time"),
                            new OA\Property(property: "updated_at", type: "string", format: "date-time"),
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
    #[OA\Response(
        response: 401,
        description: "Non authentifié"
    )]
    #[OA\Response(
        response: 404,
        description: "Profil vendeur introuvable"
    )]
    public function getVendorProducts(GetVendorProductsRequest $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');

        $dto = GetVendorProductsDto::fromRequest($request->validated(), $publicId);

        try {
            $result = $this->productService->getProductsForVendor($dto);
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
    #[OA\Post(
        path: "/api/products/info",
        tags: ["Products"],
        summary: "Récupérer les informations complètes d'un produit",
        description: "Retourne les informations détaillées d'un produit (prix, stock, catégories, moyens de paiement, attributs, combinaisons, tags). Si FromSearch=true, associe cette consultation au terme de recherche fourni pour alimenter les statistiques de pertinence. UserPublicID est déduit du token JWT si présent (route accessible aux invités).",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["ProductID"],
            properties: [
                new OA\Property(property: "ProductID", type: "integer", example: 12345),
                new OA\Property(property: "FromSearch", type: "boolean", nullable: true, example: true),
                new OA\Property(property: "SearchTerm", type: "string", nullable: true, example: "wireless headphones"),
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Informations produit récupérées avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "data", type: "object"),
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
        description: "Erreur de validation",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string"),
            ]
        )
    )]
    public function getProductInfo(GetProductInfoRequest $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id'); // peut être null (route ouverte aux invités)
        $validated = $request->validated();

        $dto = GetProductInfoDto::fromArray([
            'ProductID'    => $validated['ProductID'],
            'FromSearch'   => $validated['FromSearch'] ?? false,
            'SearchTerm'   => $validated['SearchTerm'] ?? null,
            'userPublicId' => $publicId,
            'ipAddress'    => $request->ip(),
        ]);

        try {
            $result = $this->productService->getProductInfo($dto);
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
        path: "/api/products/{product}/similar",
        tags: ["Products"],
        summary: "Lister les produits similaires",
        description: "Retourne les produits dont le nom commence par le même premier mot que le produit de référence (heuristique de type de produit), triés par popularité (commandes puis likes).",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "product",
        in: "path",
        required: true,
        description: "Identifiant du produit de référence.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 12
    )]
    #[OA\Parameter(
        name: "limit",
        in: "query",
        required: false,
        schema: new OA\Schema(type: "integer", default: 10, minimum: 1, maximum: 50)
    )]
    #[OA\Response(
        response: 200,
        description: "Produits similaires récupérés avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "data", type: "array", items: new OA\Items(type: "object")),
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
    public function getSimilarProducts(Request $request, int $product): JsonResponse
    {
        if ($product <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de produit invalide.',
            ], 404);
        }

        $limit = (int) $request->query('limit', 10);

        try {
            $result = $this->productService->getSimilarProducts($product, $limit);
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
        path: "/api/products/vendor/{vendorProfileID}",
        tags: ["Products"],
        summary: "Lister les produits publics d'un vendeur",
        description: "Retourne la liste paginée des produits d'un vendeur. UserPublicID est déduit du token JWT si présent (route accessible aux invités). IsLiked et IsWishedList sont calculés si l'utilisateur est authentifié.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "vendorProfileID",
        in: "path",
        required: true,
        description: "Identifiant du profil vendeur.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 5
    )]
    #[OA\Parameter(name: "category_id", in: "query", required: false, schema: new OA\Schema(type: "integer"), example: 10)]
    #[OA\Parameter(name: "page",        in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
    #[OA\Parameter(name: "per_page",    in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20))]
    #[OA\Response(
        response: 200,
        description: "Produits du vendeur récupérés avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(type: "object")
                ),
                new OA\Property(
                    property: "meta",
                    type: "object",
                    properties: [
                        new OA\Property(property: "total",       type: "integer", example: 48),
                        new OA\Property(property: "page",        type: "integer", example: 1),
                        new OA\Property(property: "page_size",   type: "integer", example: 20),
                        new OA\Property(property: "last_page",   type: "integer", example: 3),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Vendeur introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Vendeur introuvable."),
            ]
        )
    )]
    public function getVendorPublicProducts(Request $request, int $vendorProfileID): JsonResponse
    {
        if ($vendorProfileID <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de profil vendeur invalide.',
            ], 404);
        }

        $userPublicID = $request->attributes->get('user_id'); // null if guest
        $categoryID   = $request->query('category_id') ? (int) $request->query('category_id') : null;
        $pageNumber   = max(1, (int) $request->query('page', 1));
        $pageSize     = min(100, max(1, (int) $request->query('per_page', 20)));

        try {
            $result = $this->productService->getVendorPublicProducts(
                vendorProfileID: $vendorProfileID,
                userPublicID: $userPublicID,
                categoryID: $categoryID,
                pageNumber: $pageNumber,
                pageSize: $pageSize,
            );
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
            'data' => array_map(
                fn($item) => $item->toArray(),
                $result['data']
            ),
            'meta' => [
                'total'     => $result['total'],
                'page'      => $result['page'],
                'page_size' => $result['pageSize'],
                'last_page' => $result['totalPages'],
            ],
        ], 200);
    }
}
