<?php

namespace App\Http\Controllers;

use App\DTOs\ConfigAttributeOption\CreateConfigAttributeOptionDto;
use App\DTOs\ConfigAttributeOption\UpdateConfigAttributeOptionDto;
use App\Exceptions\BusinessValidationException;
use App\Http\Requests\ConfigAttributeOption\CreateConfigAttributeOptionRequest;
use App\Http\Requests\ConfigAttributeOption\UpdateConfigAttributeOptionRequest;
use App\Services\Interface\ConfigAttributeOptionServiceInterface;
use App\Services\Interface\ProductsConfigAttributeServiceInterface;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "ConfigAttributeOptions",
    description: "Gestion des options des attributs de configuration produit"
)]
class ConfigAttributeOptionController extends Controller
{
    public function __construct(
        protected ConfigAttributeOptionServiceInterface $configAttributeOptionService,
        private ProductsConfigAttributeServiceInterface $productsConfigAttributeService
    ) {
    }

    #[OA\Post(
        path: "/api/config-attribute-options/create",
        tags: ["ConfigAttributeOptions"],
        summary: "Créer une option d'attribut de configuration produit",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["ProductsConfigAttributeID", "OptionLabel", "OptionValue"],
            properties: [
                new OA\Property(property: "ProductsConfigAttributeID", type: "integer", example: 4),
                new OA\Property(property: "OptionLabel", type: "string", example: "Rouge"),
                new OA\Property(property: "OptionValue", type: "string", example: "red"),
                new OA\Property(property: "DisplayOrder", type: "integer", nullable: true, example: 1),
                new OA\Property(property: "IsDefaultForAttribute", type: "boolean", nullable: true, example: false),
            ]
        )
    )]
    #[OA\Response(response: 201, description: "Option créée")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 422, description: "Règle métier violée (libellé déjà pris pour cet attribut, attribut introuvable, ...)")]
    public function store(CreateConfigAttributeOptionRequest $request): JsonResponse
    {
        $request->validated();

        $attributeId = (int) $request->input('ProductsConfigAttributeID');

        if (!$this->productsConfigAttributeService->existsById($attributeId)) {
            return response()->json([
                'success' => false,
                'message' => 'L\'attribut spécifié n\'existe pas.'
            ], 422);
        }

        $isExistingOption = $this->configAttributeOptionService->existsByName($attributeId, $request->input('OptionLabel'));
        if ($isExistingOption) {
            return response()->json([
                'success' => false,
                'message' => 'Une option avec ce libellé existe déjà pour cet attribut.'
            ], 422);
        }

        $dto = CreateConfigAttributeOptionDto::fromRequest($request);

        try {
            $option = $this->configAttributeOptionService->create($dto);
        } catch (BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Option créée avec succès',
            'data' => $option
        ], 201);
    }

    #[OA\Get(
        path: "/api/config-attribute-options/exists",
        tags: ["ConfigAttributeOptions"],
        summary: "Vérifier si une option existe par son libellé pour un attribut donné",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "attributeID", in: "query", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "label", in: "query", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Succès")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 422, description: "Paramètres manquants")]
    public function existsByName(Request $request): JsonResponse
    {
        $attributeId = $request->query('attributeID');
        $label = $request->query('label');

        if (empty($attributeId) || empty($label)) {
            return response()->json([
                'success' => false,
                'message' => 'Les paramètres "attributeID" et "label" sont requis.',
            ], 422);
        }

        $exists = $this->configAttributeOptionService->existsByName((int) $attributeId, $label);

        return response()->json([
            'success' => true,
            'exists' => $exists,
        ]);
    }

    #[OA\Put(
        path: "/api/config-attribute-options/{id}",
        tags: ["ConfigAttributeOptions"],
        summary: "Mettre à jour une option d'attribut de configuration produit",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "ProductsConfigAttributeID", type: "integer", example: 4),
                new OA\Property(property: "OptionLabel", type: "string", example: "Rouge"),
                new OA\Property(property: "OptionValue", type: "string", example: "red"),
                new OA\Property(property: "DisplayOrder", type: "integer", nullable: true, example: 1),
                new OA\Property(property: "IsDefaultForAttribute", type: "boolean", nullable: true, example: false),
            ]
        )
    )]
    #[OA\Response(response: 200, description: "Option mise à jour")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Option introuvable")]
    #[OA\Response(response: 422, description: "Règle métier violée")]
    public function update(int $id, UpdateConfigAttributeOptionRequest $request): JsonResponse
    {
        $request->validated();

        $existingOption = $this->configAttributeOptionService->findById($id);
        if (!$existingOption) {
            return response()->json([
                'success' => false,
                'message' => 'Option introuvable.',
            ], 404);
        }

        if ($request->filled('ProductsConfigAttributeID')) {
            $attributeId = (int) $request->input('ProductsConfigAttributeID');
            if (!$this->productsConfigAttributeService->existsById($attributeId)) {
                return response()->json([
                    'success' => false,
                    'message' => 'L\'attribut spécifié n\'existe pas.'
                ], 422);
            }
        }

        $dto = UpdateConfigAttributeOptionDto::fromRequest($request, $existingOption);

        try {
            $this->configAttributeOptionService->update($id, $dto);
        } catch (BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Option mise à jour avec succès',
        ]);
    }

    #[OA\Put(
        path: "/api/config-attribute-options/{id}/disable",
        tags: ["ConfigAttributeOptions"],
        summary: "Désactiver une option",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Option désactivée")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Option introuvable")]
    public function disable(int $id): JsonResponse
    {
        if (!$this->configAttributeOptionService->existsById($id)) {
            return response()->json([
                'success' => false,
                'message' => 'Option introuvable.',
            ], 404);
        }

        $this->configAttributeOptionService->disable($id);

        return response()->json([
            'success' => true,
            'message' => 'Option désactivée avec succès',
        ]);
    }

    #[OA\Put(
        path: "/api/config-attribute-options/{id}/enable",
        tags: ["ConfigAttributeOptions"],
        summary: "Activer une option",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Option activée")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Option introuvable")]
    public function enable(int $id): JsonResponse
    {
        if (!$this->configAttributeOptionService->existsById($id)) {
            return response()->json([
                'success' => false,
                'message' => 'Option introuvable.',
            ], 404);
        }

        $this->configAttributeOptionService->enable($id);

        return response()->json([
            'success' => true,
            'message' => 'Option activée avec succès',
        ]);
    }

    #[OA\Get(
        path: "/api/config-attribute-options/admin",
        tags: ["ConfigAttributeOptions"],
        summary: "Liste des options pour l'administration (avec filtres, recherche, pagination)",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "search", in: "query", schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "isActive", in: "query", schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "productsConfigAttributeID", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "sortBy", in: "query", schema: new OA\Schema(type: "string", enum: ["OptionLabel", "CreatedAt", "UpdatedAt", "IsActive", "DisplayOrder"]))]
    #[OA\Parameter(name: "sortDir", in: "query", schema: new OA\Schema(type: "string", enum: ["asc", "desc"]))]
    #[OA\Parameter(name: "page", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "perPage", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Succès")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    public function adminIndex(Request $request): JsonResponse
    {
        $filters = [
            'search'                    => $request->query('search'),
            'isActive'                  => $request->has('isActive') ? filter_var($request->query('isActive'), FILTER_VALIDATE_BOOLEAN) : null,
            'productsConfigAttributeID' => $request->query('productsConfigAttributeID'),
            'sortBy'                    => $request->query('sortBy'),
            'sortDir'                   => $request->query('sortDir'),
        ];

        $page    = (int) $request->query('page', 1);
        $perPage = (int) $request->query('perPage', 20);

        $result = $this->configAttributeOptionService->getAllForAdmin($filters, $page, $perPage);

        return response()->json([
            'success' => true,
            'message' => 'Options récupérées avec succès',
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
        path: "/api/config-attribute-options",
        tags: ["ConfigAttributeOptions"],
        summary: "Liste légère des options actives (ID + Label uniquement, filtrable par attribut)"
    )]
    #[OA\Parameter(name: "productsConfigAttributeID", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "name", in: "query", schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "page", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "perPage", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Succès")]
    public function index(Request $request): JsonResponse
    {
        $filters = [
            'productsConfigAttributeID' => $request->query('productsConfigAttributeID'),
            'name'                      => $request->query('name'),
        ];

        $page    = (int) $request->query('page', 1);
        $perPage = (int) $request->query('perPage', 20);

        $result = $this->configAttributeOptionService->getAll($filters, $page, $perPage);

        return response()->json([
            'success' => true,
            'message' => 'Options récupérées avec succès',
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
        path: "/api/config-attribute-options/by-attribute/{attributeID}",
        tags: ["ConfigAttributeOptions"],
        summary: "Liste de toutes les options actives d'un attribut donné"
    )]
    #[OA\Parameter(name: "attributeID", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Succès")]
    #[OA\Response(response: 404, description: "Attribut introuvable")]
    public function getAllOptionsByAttributeID(int $attributeID): JsonResponse
    {
        if (!$this->productsConfigAttributeService->existsById($attributeID)) {
            return response()->json([
                'success' => false,
                'message' => 'Attribut introuvable.',
            ], 404);
        }

        $options = $this->configAttributeOptionService->getAllOptionsByAttributeID($attributeID);

        return response()->json([
            'success' => true,
            'message' => 'Options récupérées avec succès',
            'data' => $options,
        ]);
    }
}