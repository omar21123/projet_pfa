<?php

namespace App\Http\Controllers;

use App\DTOs\Tag\CreateTagDto;
use App\Http\Requests\Tag\CreateTagRequest;
use App\Http\Requests\Tag\CreateTagByNameRequest;
use App\Services\Interface\TagServiceInterface;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Tags",
    description: "Gestion des tags"
)]
class TagController extends Controller
{
    public function __construct(
        protected TagServiceInterface $tagService
    ) {
    }

    #[OA\Post(
        path: "/api/tags/create",
        tags: ["Tags"],
        summary: "Créer un tag",
        description: "Permet de créer un nouveau tag avec nom, couleur et description.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\MediaType(
            mediaType: "application/json",
            schema: new OA\Schema(
                required: ["Name"],
                properties: [
                    new OA\Property(property: "Name", type: "string", example: "Promotion"),
                    new OA\Property(property: "Color", type: "string", nullable: true, example: "#FF5733"),
                    new OA\Property(property: "Description", type: "string", nullable: true, example: "Produits en promotion"),
                ]
            )
        )
    )]
    #[OA\Response(response: 201, description: "Tag créé")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 422, description: "Un tag avec ce nom existe déjà")]
    public function store(CreateTagRequest $request): JsonResponse
    {
        $request->validated();

        $dto = CreateTagDto::fromRequest($request);

        $isExistingTag = $this->tagService->existsByName($dto->name);
        if ($isExistingTag) {
            return response()->json([
                'success' => false,
                'message' => 'Un tag avec ce nom existe déjà.'
            ], 422);
        }

        try {
            $tag = $this->tagService->create($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Tag créé avec succès',
            'data' => $tag
        ], 201);
    }

    #[OA\Post(
        path: "/api/tags/create-by-name",
        tags: ["Tags"],
        summary: "Créer un tag à partir du nom uniquement",
        description: "Crée un tag en ne fournissant que le nom ; Color, Description et IsActive utilisent leurs valeurs par défaut. Retourne l'ID du tag créé.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\MediaType(
            mediaType: "application/json",
            schema: new OA\Schema(
                required: ["Name"],
                properties: [
                    new OA\Property(property: "Name", type: "string", example: "Nouveauté"),
                ]
            )
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Tag créé",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Tag créé avec succès"),
                new OA\Property(property: "data", properties: [
                    new OA\Property(property: "id", type: "integer", example: 42),
                ], type: "object"),
            ]
        )
    )]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 422, description: "Un tag avec ce nom existe déjà")]
    public function storeByName(CreateTagByNameRequest $request): JsonResponse
    {
        $request->validated();

        $name = $request->input('Name');

        $isExistingTag = $this->tagService->existsByName($name);
        if ($isExistingTag) {
            return response()->json([
                'success' => false,
                'message' => 'Un tag avec ce nom existe déjà.'
            ], 422);
        }

        try {
            $id = $this->tagService->createByName($name);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Tag créé avec succès',
            'data' => ['id' => $id],
        ], 201);
    }

    #[OA\Get(
        path: "/api/tags",
        tags: ["Tags"],
        summary: "Liste des tags (avec filtres, recherche, pagination)"
    )]
    #[OA\Parameter(name: "search", in: "query", schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "isActive", in: "query", schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "sortBy", in: "query", schema: new OA\Schema(type: "string", enum: ["Name", "CreatedAt", "IsActive"]))]
    #[OA\Parameter(name: "sortDir", in: "query", schema: new OA\Schema(type: "string", enum: ["asc", "desc"]))]
    #[OA\Parameter(name: "page", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "perPage", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Succès")]
    public function index(Request $request): JsonResponse
    {
        $filters = [
            'search'   => $request->query('search'),
            'isActive' => $request->has('isActive') ? filter_var($request->query('isActive'), FILTER_VALIDATE_BOOLEAN) : null,
            'sortBy'   => $request->query('sortBy'),
            'sortDir'  => $request->query('sortDir'),
        ];

        $page    = (int) $request->query('page', 1);
        $perPage = (int) $request->query('perPage', 20);

        $result = $this->tagService->getAll($filters, $page, $perPage);

        return response()->json([
            'success' => true,
            'message' => 'Tags récupérés avec succès',
            'data' => $result['data'],
            'pagination' => [
                'total' => $result['total'],
                'page' => $result['page'],
                'perPage' => $result['perPage'],
                'lastPage' => $result['lastPage'],
            ],
        ]);
    }
    #[OA\Post(
        path: "/api/tags/{id}/disable",
        tags: ["Tags"],
        summary: "Désactiver un tag",
        description: "Met à jour le statut d'un tag existant en le désactivant (IsActive = 0).",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer"),
        example: 42
    )]
    #[OA\Response(
        response: 200,
        description: "Tag désactivé avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Tag désactivé avec succès"),
                new OA\Property(property: "data", properties: [
                    new OA\Property(property: "id", type: "integer", example: 42),
                    new OA\Property(property: "isActive", type: "boolean", example: false),
                ], type: "object"),
            ]
        )
    )]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 404, description: "Tag introuvable")]
    public function disable(int $id): JsonResponse
    {
        $isExistingTag = $this->tagService->existsById($id);
        if (!$isExistingTag) {
            return response()->json([
                'success' => false,
                'message' => 'Tag introuvable.'
            ], 404);
        }

        try {
            $tag = $this->tagService->updateStatus($id, false);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Tag désactivé avec succès',
            'data' => $tag,
        ], 200);
    }
}