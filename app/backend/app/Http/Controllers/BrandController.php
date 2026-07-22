<?php

namespace App\Http\Controllers;

use App\DTOs\Brand\CreateBrandDto;
use App\DTOs\Brand\UpdateBrandDto;
use App\Http\Requests\Brand\CreateBrandRequest;
use App\Http\Requests\Brand\UpdateBrandRequest;
use App\Services\Interface\BrandServiceInterface;
use App\Services\Interface\CountryServiceInterface;
use App\Services\Interface\FileUploadServiceInterface;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log; // <-- add this
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Brands",
    description: "Gestion des marques"
)]
class BrandController extends Controller
{
    public function __construct(
        protected BrandServiceInterface $brandService,
        private FileUploadServiceInterface $fileUploadService ,
        private CountryServiceInterface $CountryService
    ) {
    }

    #[OA\Post(
        path: "/api/brands/create",
        tags: ["Brands"],
        summary: "Créer une marque",
        description: "Permet de créer une nouvelle marque (réservé aux administrateurs).",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\MediaType(
            mediaType: "multipart/form-data",
            schema: new OA\Schema(
                required: ["Name"],
                properties: [
                    new OA\Property(property: "Name", type: "string", example: "Samsung"),
                    new OA\Property(property: "Website", type: "string", nullable: true, example: "https://samsung.com"),
                    new OA\Property(property: "Description", type: "string", nullable: true, example: "Fabricant sud-coréen d'électronique"),
                    new OA\Property(property: "CountryID", type: "integer", nullable: true, example: 12),
                    new OA\Property(
                        property: "LogoURL",
                        type: "string",
                        format: "binary",
                        nullable: true,
                        description: "Logo de la marque (jpg, jpeg, png, webp - max 2MB)"
                    ),
                ]
            )
        )
    )]
    #[OA\Response(response: 201, description: "Marque créée")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 422, description: "Règle métier violée (nom déjà pris, pays introuvable, ...)")]
public function store(CreateBrandRequest $request): JsonResponse
{
    $request->validated();

    $countryId = $request->filled('CountryID') ? (int) $request->input('CountryID') : null;
    if ($countryId !== null) {
        $countryExists = $this->CountryService->isExistsByID($countryId);
        if ($countryExists === false) {
            return response()->json([
                'success' => false,
                'message' => 'Ce pays n\existe pas dans notre base de données.'
            ], 422);
        }
    }

    $isExistingBrand = $this->brandService->existsByName($request->input('Name'));
    if ($isExistingBrand) {
        return response()->json([
            'success' => false,
            'message' => 'Une marque avec ce nom existe déjà.'
        ], 422);
    }

    $logoUrl = $request->hasFile('LogoURL')
        ? $this->fileUploadService->storeAvatar($request->file('LogoURL'))
        : null;

    $dto = CreateBrandDto::fromRequest($request, $logoUrl);

    try {
        $brand = $this->brandService->create($dto);
    } catch (\App\Exceptions\BusinessValidationException $e) {
        return response()->json([
            'success' => false,
            'message' => $e->getMessage(),
        ], $e->getCode() ?: 422);
    }

    return response()->json([
        'success' => true,
        'message' => 'Marque créée avec succès',
        'data' => $brand
    ], 201);
}

    #[OA\Get(
        path: "/api/brands/exists",
        tags: ["Brands"],
        summary: "Vérifier si une marque existe par son nom",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "name", in: "query", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(
        response: 200,
        description: "Succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "exists", type: "boolean", example: true),
            ]
        )
    )]
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

        $exists = $this->brandService->existsByName($name);

        return response()->json([
            'success' => true,
            'exists' => $exists,
        ]);
    }

    #[OA\Put(
        path: "/api/brands/{id}",
        tags: ["Brands"],
        summary: "Mettre à jour une marque",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\RequestBody(
        required: true,
        content: new OA\MediaType(
            mediaType: "multipart/form-data",
            schema: new OA\Schema(
                required: ["Name"],
                properties: [
                    new OA\Property(property: "Name", type: "string", example: "Samsung"),
                    new OA\Property(property: "Website", type: "string", nullable: true, example: "https://samsung.com"),
                    new OA\Property(property: "Description", type: "string", nullable: true, example: "Fabricant sud-coréen d'électronique"),
                    new OA\Property(property: "CountryID", type: "integer", nullable: true, example: 12),
                    new OA\Property(
                        property: "LogoURL",
                        type: "string",
                        format: "binary",
                        nullable: true,
                        description: "Nouveau logo (optionnel — l'ancien est conservé si absent)"
                    ),
                ]
            )
        )
    )]
    #[OA\Response(response: 200, description: "Marque mise à jour")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Marque introuvable")]
    #[OA\Response(response: 422, description: "Règle métier violée")]
    public function update(int $id, UpdateBrandRequest $request): JsonResponse
    {
        $request->validated();

        $countryId = $request->filled('CountryID') ? (int) $request->input('CountryID') : null;
        if ($countryId !== null) {
            $countryExists = $this->CountryService->isExistsByID($countryId);
            if ($countryExists === false) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce pays n\existe pas dans notre base de données.'
                ], 422);
            }
        }
        Log::debug('Incoming request', [
    'input'   => $request->all(),
    'headers' => $request->headers->all(),
]);

        $existingBrand = $this->brandService->findById($id);
        if (!$existingBrand) {
            return response()->json([
                'success' => false,
                'message' => 'Marque introuvable.',
            ], 404);
        }

        $logoUrl = $request->hasFile('LogoURL')
            ? $this->fileUploadService->storeAvatar($request->file('LogoURL'))
            : $existingBrand->LogoURL;

        $dto = UpdateBrandDto::fromRequest($request, $logoUrl, $existingBrand);

        try {
            $this->brandService->update($id, $dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Marque mise à jour avec succès',
        ]);
    }

    #[OA\Put(
        path: "/api/brands/{id}/disable",
        tags: ["Brands"],
        summary: "Désactiver une marque",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Marque désactivée")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Marque introuvable")]
    public function disable(int $id): JsonResponse
    {
        if (!$this->brandService->existsById($id)) {
            return response()->json([
                'success' => false,
                'message' => 'Marque introuvable.',
            ], 404);
        }

        $this->brandService->disable($id);

        return response()->json([
            'success' => true,
            'message' => 'Marque désactivée avec succès',
        ]);
    }

    #[OA\Put(
        path: "/api/brands/{id}/enable",
        tags: ["Brands"],
        summary: "Activer une marque",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Marque activée")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Marque introuvable")]
    public function enable(int $id): JsonResponse
    {
        if (!$this->brandService->existsById($id)) {
            return response()->json([
                'success' => false,
                'message' => 'Marque introuvable.',
            ], 404);
        }

        $this->brandService->enable($id);

        return response()->json([
            'success' => true,
            'message' => 'Marque activée avec succès',
        ]);
    }

    #[OA\Get(
        path: "/api/brands/admin",
        tags: ["Brands"],
        summary: "Liste des marques pour l'administration (avec filtres, recherche, pagination)",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "search", in: "query", schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "isActive", in: "query", schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "countryID", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "sortBy", in: "query", schema: new OA\Schema(type: "string", enum: ["Name", "CreatedAt", "UpdatedAt", "IsActive"]))]
    #[OA\Parameter(name: "sortDir", in: "query", schema: new OA\Schema(type: "string", enum: ["asc", "desc"]))]
    #[OA\Parameter(name: "page", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "perPage", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Succès")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    public function adminIndex(Request $request): JsonResponse
    {
        $filters = [
            'search'    => $request->query('search'),
            'isActive'  => $request->has('isActive') ? filter_var($request->query('isActive'), FILTER_VALIDATE_BOOLEAN) : null,
            'countryID' => $request->query('countryID'),
            'sortBy'    => $request->query('sortBy'),
            'sortDir'   => $request->query('sortDir'),
        ];

        $page    = (int) $request->query('page', 1);
        $perPage = (int) $request->query('perPage', 20);

        $result = $this->brandService->getAllForAdmin($filters, $page, $perPage);

        return response()->json([
            'success' => true,
            'message' => 'Marques récupérées avec succès',
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
        path: "/api/brands",
        tags: ["Brands"],
        summary: "Liste publique des marques actives (filtre par ID ou nom, wildcard sur le nom)"
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

        $result = $this->brandService->getAllPublic($filters, $page, $perPage);

        return response()->json([
            'success' => true,
            'message' => 'Marques récupérées avec succès',
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