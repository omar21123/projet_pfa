<?php

namespace App\Http\Controllers;

use App\DTOs\Unit\CreateUnitDto;
use App\DTOs\Unit\UpdateUnitDto;
use App\Http\Requests\Unit\CreateUnitRequest;
use App\Http\Requests\Unit\UpdateUnitRequest;
use App\Services\Interface\UnitServiceInterface;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Units",
    description: "Gestion des unités de mesure"
)]
class UnitController extends Controller
{
    public function __construct(
        protected UnitServiceInterface $unitService
    ) {
    }

    #[OA\Post(
        path: "/api/units/create",
        tags: ["Units"],
        summary: "Créer une unité",
        description: "Permet de créer une nouvelle unité de mesure (réservé aux administrateurs).",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\MediaType(
            mediaType: "application/json",
            schema: new OA\Schema(
                required: ["Name", "Symbol"],
                properties: [
                    new OA\Property(property: "Name", type: "string", example: "Kilogramme"),
                    new OA\Property(property: "Symbol", type: "string", example: "kg"),
                    new OA\Property(property: "DisplayOrder", type: "integer", nullable: true, example: 1),
                ]
            )
        )
    )]
    #[OA\Response(response: 201, description: "Unité créée")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 422, description: "Une unité avec ce nom existe déjà")]
    public function store(CreateUnitRequest $request): JsonResponse
    {
        $request->validated();

        $isExistingUnit = $this->unitService->existsByName($request->input('Name'));
        if ($isExistingUnit) {
            return response()->json([
                'success' => false,
                'message' => 'Une unité avec ce nom existe déjà.'
            ], 422);
        }

        $dto = CreateUnitDto::fromRequest($request);
        $unit = $this->unitService->create($dto);

        return response()->json([
            'success' => true,
            'message' => 'Unité créée avec succès',
            'data' => $unit
        ], 201);
    }

    #[OA\Put(
        path: "/api/units/{id}",
        tags: ["Units"],
        summary: "Mettre à jour une unité",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\RequestBody(
        required: true,
        content: new OA\MediaType(
            mediaType: "application/json",
            schema: new OA\Schema(
                required: ["Name", "Symbol"],
                properties: [
                    new OA\Property(property: "Name", type: "string", example: "Kilogramme"),
                    new OA\Property(property: "Symbol", type: "string", example: "kg"),
                    new OA\Property(property: "DisplayOrder", type: "integer", nullable: true, example: 1),
                ]
            )
        )
    )]
    #[OA\Response(response: 200, description: "Unité mise à jour")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Unité introuvable")]
    #[OA\Response(response: 422, description: "Une unité avec ce nom existe déjà")]
    public function update(int $id, UpdateUnitRequest $request): JsonResponse
    {
        $request->validated();

        $existingUnit = $this->unitService->findById($id);
        if (!$existingUnit) {
            return response()->json([
                'success' => false,
                'message' => 'Unité introuvable.',
            ], 404);
        }

        $isNameTaken = $this->unitService->existsByName($request->input('Name'));
        if ($isNameTaken && strcasecmp($existingUnit->Name, $request->input('Name')) !== 0) {
            return response()->json([
                'success' => false,
                'message' => 'Une unité avec ce nom existe déjà.'
            ], 422);
        }

        $dto = UpdateUnitDto::fromRequest($request);
        $this->unitService->update($id, $dto);

        return response()->json([
            'success' => true,
            'message' => 'Unité mise à jour avec succès',
        ]);
    }

    #[OA\Put(
        path: "/api/units/{id}/disable",
        tags: ["Units"],
        summary: "Désactiver une unité",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Unité désactivée")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Unité introuvable")]
    public function disable(int $id): JsonResponse
    {
        if (!$this->unitService->existsById($id)) {
            return response()->json([
                'success' => false,
                'message' => 'Unité introuvable.',
            ], 404);
        }

        $this->unitService->disable($id);

        return response()->json([
            'success' => true,
            'message' => 'Unité désactivée avec succès',
        ]);
    }

    #[OA\Put(
        path: "/api/units/{id}/enable",
        tags: ["Units"],
        summary: "Activer une unité",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Unité activée")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Unité introuvable")]
    public function enable(int $id): JsonResponse
    {
        if (!$this->unitService->existsById($id)) {
            return response()->json([
                'success' => false,
                'message' => 'Unité introuvable.',
            ], 404);
        }

        $this->unitService->enable($id);

        return response()->json([
            'success' => true,
            'message' => 'Unité activée avec succès',
        ]);
    }

    #[OA\Get(
        path: "/api/units/admin",
        tags: ["Units"],
        summary: "Liste des unités pour l'administration (avec filtres, recherche, pagination)",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "search", in: "query", schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "isActive", in: "query", schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "sortBy", in: "query", schema: new OA\Schema(type: "string", enum: ["Name", "IsActive", "DisplayOrder"]))]
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
            'sortBy'   => $request->query('sortBy'),
            'sortDir'  => $request->query('sortDir'),
        ];

        $page    = (int) $request->query('page', 1);
        $perPage = (int) $request->query('perPage', 20);

        $result = $this->unitService->getAllForAdmin($filters, $page, $perPage);

        return response()->json([
            'success' => true,
            'message' => 'Unités récupérées avec succès',
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
        path: "/api/units",
        tags: ["Units"],
        summary: "Liste publique des unités actives (filtre par ID ou nom)"
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

        $result = $this->unitService->getAllPublic($filters, $page, $perPage);

        return response()->json([
            'success' => true,
            'message' => 'Unités récupérées avec succès',
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