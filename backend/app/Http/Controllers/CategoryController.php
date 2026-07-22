<?php

namespace App\Http\Controllers;

use App\DTOs\Category\CategoryFilterDto;
use App\Http\Requests\Category\CreateCategoryRequest;
use App\Http\Requests\Category\UpdateCategoryRequest;
use App\Http\Requests\Category\UpdateCategoryStatusRequest;
use App\DTOs\Category\CreateCategoryDto;
use App\DTOs\Category\UpdateCategoryDto;
use App\Services\Interface\CategoryServiceInterface;
use App\Services\Interface\FileUploadServiceInterface;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Categories",
    description: "Gestion des catégories"
)]
class CategoryController extends Controller
{
    public function __construct(
        protected CategoryServiceInterface $categoryService,
        private FileUploadServiceInterface $fileUploadService
    ) {
    }

    #[OA\Post(
        path: "/api/categories/create",
        tags: ["Categories"],
        summary: "Créer une catégorie",
        description: "Permet de créer une nouvelle catégorie.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\MediaType(
            mediaType: "multipart/form-data",
            schema: new OA\Schema(
                required: ["Name"],
                properties: [
                    new OA\Property(property: "Name", type: "string", example: "Électronique"),
                    new OA\Property(property: "ParentCategoryID", type: "integer", nullable: true, example: 1),
                    new OA\Property(
                        property: "IconURL",
                        type: "string",
                        format: "binary",
                        nullable: true,
                        description: "Image de l'icône (jpg, jpeg, png, webp - max 2MB)"
                    ),
                ]
            )
        )
    )]
    #[OA\Response(response: 201, description: "Catégorie créée")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès refusé")]
    #[OA\Response(response: 422, description: "Règle métier violée (parent introuvable, slug déjà pris, ...)")]
    public function store(CreateCategoryRequest $request): JsonResponse
    {
        $request->validated();

        $iconUrl = $request->hasFile('IconURL')
            ? $this->fileUploadService->storeAvatar($request->file('IconURL'))
            : null;

        $dto = CreateCategoryDto::fromRequest($request, $iconUrl);
        $isExistingCategory = $this->categoryService->categoryExistsByName($dto->name);
        if ($isExistingCategory) {
            return response()->json([
                'success' => false,
                'message' => 'Une catégorie avec ce nom existe déjà.'
            ], 422);
        }
        if ($dto->parentCategoryID !== null) {
            $IsCategoryExists = $this->categoryService->categoryExists($dto->parentCategoryID);
            if (!$IsCategoryExists) {
                return response()->json([
                    'success' => false,
                    'message' => 'La catégorie parente spécifiée n\'existe pas.'
                ], 422);
            }
        }
        try {
            $category = $this->categoryService->createCategory($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Catégorie créée avec succès',
            'data' => $category
        ], 201);
    }
    #[OA\Get(
        path: "/api/categories",
        tags: ["Categories"],
        summary: "Liste des catégories racines (avec filtres, recherche, pagination)"
    )]
    #[OA\Parameter(name: "search", in: "query", schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "isActive", in: "query", schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "hasProducts", in: "query", schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "isEmpty", in: "query", schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "sortBy", in: "query", schema: new OA\Schema(type: "string", enum: ["Name", "CreatedAt", "UpdatedAt", "DisplayOrder"]))]
    #[OA\Parameter(name: "sortDir", in: "query", schema: new OA\Schema(type: "string", enum: ["asc", "desc"]))]
    #[OA\Parameter(name: "page", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "perPage", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Succès")]
    public function index(\Illuminate\Http\Request $request): JsonResponse
    {
        $filters = CategoryFilterDto::fromRequest($request);
        $result = $this->categoryService->getRootCategories($filters);

        return response()->json([
            'success' => true,
            'message' => 'Catégories racines récupérées avec succès',
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
        path: "/api/categories/{id}/children",
        tags: ["Categories"],
        summary: "Sous-catégories directes (avec filtres, recherche, pagination)"
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "search", in: "query", schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "isActive", in: "query", schema: new OA\Schema(type: "boolean"))]
    #[OA\Parameter(name: "sortBy", in: "query", schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "sortDir", in: "query", schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "page", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "perPage", in: "query", schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Succès")]
    #[OA\Response(response: 404, description: "Catégorie introuvable")]
    public function children(int $id, \Illuminate\Http\Request $request): JsonResponse
    {
        $filters = CategoryFilterDto::fromRequest($request);

        try {
            $result = $this->categoryService->getChildren($id, $filters);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $result['data'],
            'pagination' => [
                'total' => $result['total'],
                'page' => $result['page'],
                'perPage' => $result['perPage'],
                'lastPage' => $result['lastPage'],
            ],
        ]);
    }
    #[OA\Put(
        path: "/api/categories/{id}/deactivate-subtree",
        tags: ["Categories"],
        summary: "Désactiver une catégorie et tout son arbre de sous-catégories",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Succès")]
    #[OA\Response(response: 404, description: "Catégorie introuvable")]
    public function deactivateSubtree(int $id): JsonResponse
    {
        try {
            $this->categoryService->deactivateSubtree($id);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Catégorie et toutes ses sous-catégories désactivées avec succès',
        ]);
    }
    #[OA\Put(
        path: "/api/categories/{id}/activate",
        tags: ["Categories"],
        summary: "Activer une catégorie",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Succès")]
    #[OA\Response(response: 404, description: "Catégorie introuvable")]
    public function activate(int $id): JsonResponse
    {
        try {
            $this->categoryService->activateCategory($id);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Catégorie activée avec succès',
        ]);
    }
    #[OA\Get(
        path: "/api/categories/navbar",
        tags: ["Categories"],
        summary: "Liste des catégories actives pour le Navbar"
    )]
    #[OA\Response(
        response: 200,
        description: "Liste des catégories du Navbar"
    )]
    public function navbar(): JsonResponse
    {
        $categories = $this->categoryService->getNavbarCategories();

        return response()->json([
            'success' => true,
            'message' => 'Catégories du navbar récupérées avec succès.',
            'data' => $categories,
        ]);
    }
}
