<?php

namespace App\Http\Controllers;

use App\DTOs\ProductsConfigAttribute\CreateProductsConfigAttributeDto;
use App\DTOs\ProductsConfigAttribute\UpdateProductsConfigAttributeDto;
use App\Exceptions\BusinessValidationException;
use App\Http\Requests\ProductsConfigAttribute\CreateProductsConfigAttributeRequest;
use App\Http\Requests\ProductsConfigAttribute\UpdateProductsConfigAttributeRequest;
use App\Services\Interface\ProductsConfigAttributeServiceInterface;
use App\Services\Interface\UnitServiceInterface;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "ProductsConfigAttribute",
    description: "Gestion des attributs de configuration produit"
)]
class ProductsConfigAttributeController extends Controller
{
    public function __construct(
        protected ProductsConfigAttributeServiceInterface $productsConfigAttributeService,
        private UnitServiceInterface $unitService
    ) {
    }

    #[OA\Post(
        path: "/api/products-config-attributes/create",
        tags: ["ProductsConfigAttribute"],
        summary: "Créer un attribut de configuration produit",
        description: "Permet de créer un nouvel attribut (réservé aux administrateurs).",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["Name"],
            properties: [
                new OA\Property(property: "Name", type: "string", example: "Couleur"),
                new OA\Property(property: "UnitID", type: "integer", nullable: true, example: 3),
                new OA\Property(property: "DisplayOrder", type: "integer", nullable: true, example: 1),
            ]
        )
    )]
    #[OA\Response(response: 201, description: "Attribut créé")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 422, description: "Règle métier violée (nom déjà pris, unité introuvable, ...)")]
    public function store(CreateProductsConfigAttributeRequest $request): JsonResponse
    {
        $request->validated();

        $unitId = $request->filled('UnitID') ? (int) $request->input('UnitID') : null;
        if ($unitId !== null) {
            $unitExists = $this->unitService->existsById($unitId);
            if ($unitExists === false) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette unité n\'existe pas dans notre base de données.'
                ], 422);
            }
        }

        $isExistingAttribute = $this->productsConfigAttributeService->existsByName($request->input('Name'));
        if ($isExistingAttribute) {
            return response()->json([
                'success' => false,
                'message' => 'Un attribut avec ce nom existe déjà.'
            ], 422);
        }

        $dto = CreateProductsConfigAttributeDto::fromRequest($request);

        try {
            $attribute = $this->productsConfigAttributeService->create($dto);
        } catch (BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Attribut créé avec succès',
            'data' => $attribute
        ], 201);
    }

    #[OA\Get(
        path: "/api/products-config-attributes/exists",
        tags: ["ProductsConfigAttribute"],
        summary: "Vérifier si un attribut existe par son nom",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "name", in: "query", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Succès")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 422, description: "Paramètre 'name' manquant")]
    public function existsByName(Request $request): JsonResponse
    {
        $name = $request->query('name');

        if (empty($name)) {
            return response()->json([
                'success' => false,
                'message' => 'Le paramètre "name" est requis.',
            ], 422);
        }

        $exists = $this->productsConfigAttributeService->existsByName($name);

        return response()->json([
            'success' => true,
            'exists' => $exists,
        ]);
    }

    #[OA\Put(
        path: "/api/products-config-attributes/{id}",
        tags: ["ProductsConfigAttribute"],
        summary: "Mettre à jour un attribut de configuration produit",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "Name", type: "string", example: "Couleur"),
                new OA\Property(property: "UnitID", type: "integer", nullable: true, example: 3),
                new OA\Property(property: "DisplayOrder", type: "integer", nullable: true, example: 1),
            ]
        )
    )]
    #[OA\Response(response: 200, description: "Attribut mis à jour")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Attribut introuvable")]
    #[OA\Response(response: 422, description: "Règle métier violée")]
    public function update(int $id, UpdateProductsConfigAttributeRequest $request): JsonResponse
    {
        $request->validated();

        $unitId = $request->filled('UnitID') ? (int) $request->input('UnitID') : null;
        if ($unitId !== null) {
            $unitExists = $this->unitService->existsById($unitId);
            if ($unitExists === false) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette unité n\'existe pas dans notre base de données.'
                ], 422);
            }
        }

        $existingAttribute = $this->productsConfigAttributeService->findById($id);
        if (!$existingAttribute) {
            return response()->json([
                'success' => false,
                'message' => 'Attribut introuvable.',
            ], 404);
        }

        $dto = UpdateProductsConfigAttributeDto::fromRequest($request, $existingAttribute);

        try {
            $this->productsConfigAttributeService->update($id, $dto);
        } catch (BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Attribut mis à jour avec succès',
        ]);
    }

    #[OA\Put(
        path: "/api/products-config-attributes/{id}/disable",
        tags: ["ProductsConfigAttribute"],
        summary: "Désactiver un attribut",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Attribut désactivé")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Attribut introuvable")]
    public function disable(int $id): JsonResponse
    {
        if (!$this->productsConfigAttributeService->existsById($id)) {
            return response()->json([
                'success' => false,
                'message' => 'Attribut introuvable.',
            ], 404);
        }

        $this->productsConfigAttributeService->disable($id);

        return response()->json([
            'success' => true,
            'message' => 'Attribut désactivé avec succès',
        ]);
    }

    #[OA\Put(
        path: "/api/products-config-attributes/{id}/enable",
        tags: ["ProductsConfigAttribute"],
        summary: "Activer un attribut",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Attribut activé")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Attribut introuvable")]
    public function enable(int $id): JsonResponse
    {
        if (!$this->productsConfigAttributeService->existsById($id)) {
            return response()->json([
                'success' => false,
                'message' => 'Attribut introuvable.',
            ], 404);
        }

        $this->productsConfigAttributeService->enable($id);

        return response()->json([
            'success' => true,
            'message' => 'Attribut activé avec succès',
        ]);
    }

    #[OA\Get(
        path: "/api/products-config-attributes/admin",
        tags: ["ProductsConfigAttribute"],
        summary: "Liste des attributs pour l'administration (avec filtres, recherche, pagination)",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "search", in: "query", schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "isActive", in: "query", schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "unitID", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "sortBy", in: "query", schema: new OA\Schema(type: "string", enum: ["Name", "CreatedAt", "UpdatedAt", "IsActive", "DisplayOrder"]))]
    #[OA\Parameter(name: "sortDir", in: "query", schema: new OA\Schema(type: "string", enum: ["asc", "desc"]))]
    #[OA\Parameter(name: "page", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "perPage", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Succès")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    public function adminIndex(Request $request): JsonResponse
    {
        $filters = [
            'search'   => $request->query('search'),
            'isActive' => $request->has('isActive') ? filter_var($request->query('isActive'), FILTER_VALIDATE_BOOLEAN) : null,
            'unitID'   => $request->query('unitID'),
            'sortBy'   => $request->query('sortBy'),
            'sortDir'  => $request->query('sortDir'),
        ];

        $page    = (int) $request->query('page', 1);
        $perPage = (int) $request->query('perPage', 20);

        $result = $this->productsConfigAttributeService->getAllForAdmin($filters, $page, $perPage);

        return response()->json([
            'success' => true,
            'message' => 'Attributs récupérés avec succès',
            'data' => $result['data'],
            'pagination' => [
                'total' => $result['total'],
                'page' => $result['page'],
                'perPage' => $result['perPage'],
                'lastPage' => $result['lastPage'],
            ],
        ]);
    }

    #[OA\Get(
        path: "/api/products-config-attributes",
        tags: ["ProductsConfigAttribute"],
        summary: "Liste légère des attributs actifs (ID + Name uniquement, filtre par nom)"
    )]
    #[OA\Parameter(name: "name", in: "query", schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "page", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "perPage", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Succès")]
    public function index(Request $request): JsonResponse
    {
        $filters = [
            'name' => $request->query('name'),
        ];

        $page    = (int) $request->query('page', 1);
        $perPage = (int) $request->query('perPage', 20);

        $result = $this->productsConfigAttributeService->getAll($filters, $page, $perPage);

        return response()->json([
            'success' => true,
            'message' => 'Attributs récupérés avec succès',
            'data' => $result['data'],
            'pagination' => [
                'total' => $result['total'],
                'page' => $result['page'],
                'perPage' => $result['perPage'],
                'lastPage' => $result['lastPage'],
            ],
        ]);
    }
}