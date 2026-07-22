<?php

namespace App\Http\Controllers;

use App\DTOs\ProductModel\CreateProductModelDto;
use App\DTOs\ProductModel\UpdateProductModelDto;
use App\Http\Requests\ProductModel\CreateModelRequest;
use App\Http\Requests\ProductModel\UpdateModelRequest;
use App\Services\Interface\BrandServiceInterface;
use App\Services\Interface\ProductModelServiceInterface;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Models",
    description: "Gestion des modèles de produits"
)]
class ProductModelController extends Controller
{
    public function __construct(
        protected ProductModelServiceInterface $modelService,
        private BrandServiceInterface $brandService
    ) {
    }

    #[OA\Post(
        path: "/api/models/create",
        tags: ["Models"],
        summary: "Créer un modèle",
        description: "Permet de créer un nouveau modèle rattaché à une marque (réservé aux administrateurs).",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\MediaType(
            mediaType: "application/json",
            schema: new OA\Schema(
                required: ["BrandID", "Name"],
                properties: [
                    new OA\Property(property: "BrandID", type: "integer", example: 3),
                    new OA\Property(property: "Name", type: "string", example: "Galaxy S24"),
                    new OA\Property(property: "Code", type: "string", nullable: true, example: "SM-S921B"),
                    new OA\Property(property: "Description", type: "string", nullable: true, example: "Modèle phare 2024"),
                    new OA\Property(property: "ReleaseYear", type: "integer", nullable: true, example: 2024),
                ]
            )
        )
    )]
    #[OA\Response(response: 201, description: "Modèle créé")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Marque introuvable")]
    #[OA\Response(response: 422, description: "Un modèle avec ce nom existe déjà pour cette marque")]
    public function store(CreateModelRequest $request): JsonResponse
    {
        $request->validated();

        $brandID = (int) $request->input('BrandID');

        if (!$this->brandService->existsById($brandID)) {
            return response()->json([
                'success' => false,
                'message' => 'La marque spécifiée n\'existe pas.',
            ], 404);
        }

        $isExistingModel = $this->modelService->existsByNameForBrand($brandID, $request->input('Name'));
        if ($isExistingModel) {
            return response()->json([
                'success' => false,
                'message' => 'Un modèle avec ce nom existe déjà pour cette marque.'
            ], 422);
        }

        $dto = CreateProductModelDto::fromRequest($request);

        try {
            $model = $this->modelService->create($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Modèle créé avec succès',
            'data' => $model
        ], 201);
    }

    #[OA\Put(
        path: "/api/models/{id}",
        tags: ["Models"],
        summary: "Mettre à jour les informations d'un modèle",
        description: "Met à jour uniquement les informations du modèle (Name, Code, Description, ReleaseYear) — la marque associée n'est pas modifiable via cet endpoint.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\RequestBody(
        required: true,
        content: new OA\MediaType(
            mediaType: "application/json",
            schema: new OA\Schema(
                required: ["Name"],
                properties: [
                    new OA\Property(property: "Name", type: "string", example: "Galaxy S24 Ultra"),
                    new OA\Property(property: "Code", type: "string", nullable: true, example: "SM-S928B"),
                    new OA\Property(property: "Description", type: "string", nullable: true, example: "Version Ultra 2024"),
                    new OA\Property(property: "ReleaseYear", type: "integer", nullable: true, example: 2024),
                ]
            )
        )
    )]
    #[OA\Response(response: 200, description: "Modèle mis à jour")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Modèle introuvable")]
    #[OA\Response(response: 422, description: "Un modèle avec ce nom existe déjà pour cette marque")]
    public function update(int $id, UpdateModelRequest $request): JsonResponse
    {
        $request->validated();

        $existingModel = $this->modelService->findById($id);
        if (!$existingModel) {
            return response()->json([
                'success' => false,
                'message' => 'Modèle introuvable.',
            ], 404);
        }

        $isNameTaken = $this->modelService->existsByNameForBrand($existingModel->BrandID, $request->input('Name'));
        if ($isNameTaken && strcasecmp($existingModel->Name, $request->input('Name')) !== 0) {
            return response()->json([
                'success' => false,
                'message' => 'Un modèle avec ce nom existe déjà pour cette marque.'
            ], 422);
        }

        // BrandID is intentionally carried over unchanged — this endpoint
        // only updates model info, never re-assigns the brand.
        $dto = new UpdateProductModelDto(
            brandID: $existingModel->BrandID,
            name: $request->input('Name'),
            code: $request->input('Code'),
            description: $request->input('Description'),
            releaseYear: $request->filled('ReleaseYear') ? (int) $request->input('ReleaseYear') : null,
        );

        try {
            $this->modelService->update($id, $dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Modèle mis à jour avec succès',
        ]);
    }

    #[OA\Put(
        path: "/api/models/{id}/disable",
        tags: ["Models"],
        summary: "Désactiver un modèle",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Modèle désactivé")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Modèle introuvable")]
    public function disable(int $id): JsonResponse
    {
        if (!$this->modelService->existsById($id)) {
            return response()->json([
                'success' => false,
                'message' => 'Modèle introuvable.',
            ], 404);
        }

        $this->modelService->disable($id);

        return response()->json([
            'success' => true,
            'message' => 'Modèle désactivé avec succès',
        ]);
    }

    #[OA\Put(
        path: "/api/models/{id}/enable",
        tags: ["Models"],
        summary: "Activer un modèle",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Modèle activé")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Modèle introuvable")]
    public function enable(int $id): JsonResponse
    {
        if (!$this->modelService->existsById($id)) {
            return response()->json([
                'success' => false,
                'message' => 'Modèle introuvable.',
            ], 404);
        }

        $this->modelService->enable($id);

        return response()->json([
            'success' => true,
            'message' => 'Modèle activé avec succès',
        ]);
    }

    #[OA\Get(
        path: "/api/models/admin",
        tags: ["Models"],
        summary: "Liste des modèles pour l'administration (avec filtres, recherche, pagination)",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "search", in: "query", schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "isActive", in: "query", schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "brandID", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "sortBy", in: "query", schema: new OA\Schema(type: "string", enum: ["Name", "CreatedAt", "UpdatedAt", "IsActive", "ReleaseYear"]))]
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
            'brandID'  => $request->query('brandID'),
            'sortBy'   => $request->query('sortBy'),
            'sortDir'  => $request->query('sortDir'),
        ];

        $page    = (int) $request->query('page', 1);
        $perPage = (int) $request->query('perPage', 20);

        $result = $this->modelService->getAllForAdmin($filters, $page, $perPage);

        return response()->json([
            'success' => true,
            'message' => 'Modèles récupérés avec succès',
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
        path: "/api/models",
        tags: ["Models"],
        summary: "Liste publique des modèles actifs (filtre par ID ou nom, wildcard sur le nom)"
    )]
    #[OA\Parameter(name: "id", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "name", in: "query", schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "page", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "perPage", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Succès")]
    public function publicIndex(Request $request): JsonResponse
    {
        $filters = [
            'id'   => $request->query('id'),
            'name' => $request->query('name'),
        ];

        $page    = (int) $request->query('page', 1);
        $perPage = (int) $request->query('perPage', 20);

        $result = $this->modelService->getAllPublic($filters, $page, $perPage);

        return response()->json([
            'success' => true,
            'message' => 'Modèles récupérés avec succès',
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