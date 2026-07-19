<?php

namespace App\Http\Controllers;

use App\DTOs\Product\CreateProductDto;
use App\DTOs\Product\GetAllProductsAdminDto;
use App\Http\Requests\Product\CreateProductRequest;
use App\Http\Requests\Product\GetAllProductsAdminRequest;
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
}
