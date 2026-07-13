<?php

namespace App\Http\Controllers;

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
    if($dto->parentCategoryID !== null){
        $IsCategoryExists = $this->categoryService->categoryExists($dto->parentCategoryID);
        if(!$IsCategoryExists){
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
        summary: "Liste des catégories"
    )]
    #[OA\Response(response: 200, description: "Succès")]
    public function index(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Arbre des catégories récupéré avec succès',
            'data' => $this->categoryService->getCategoryTreeNested()
        ]);
    }

    #[OA\Put(
        path: "/api/categories/{id}",
        tags: ["Categories"],
        summary: "Modifier une catégorie",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer")
    )]
    #[OA\Response(response: 200, description: "Succès")]
    public function update(UpdateCategoryRequest $request, int $id): JsonResponse
    {
        $dto = UpdateCategoryDto::fromRequest($request);

        $success = $this->categoryService->updateCategory($id, $dto);

        if (!$success) {
            return response()->json([
                'success' => false,
                'message' => 'Catégorie introuvable'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Catégorie mise à jour avec succès'
        ]);
    }

    #[OA\Put(
        path: "/api/categories/{id}/status",
        tags: ["Categories"],
        summary: "Activer/Désactiver une catégorie",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer")
    )]
    #[OA\Response(response: 200, description: "Succès")]
    public function updateStatus(UpdateCategoryStatusRequest $request, int $id): JsonResponse
    {
        $success = $this->categoryService->updateCategoryStatus(
            $id,
            (bool) $request->validated('IsActive')
        );

        if (!$success) {
            return response()->json([
                'success' => false,
                'message' => 'Catégorie introuvable'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Statut mis à jour avec succès'
        ]);
    }

    #[OA\Delete(
        path: "/api/categories/{id}",
        tags: ["Categories"],
        summary: "Supprimer une catégorie",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer")
    )]
    #[OA\Response(response: 200, description: "Succès")]
    public function destroy(int $id): JsonResponse
    {
        $success = $this->categoryService->deleteCategory($id);

        if (!$success) {
            return response()->json([
                'success' => false,
                'message' => 'Catégorie introuvable'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Catégorie supprimée avec succès'
        ]);
    }
    #[OA\Get(
        path: "/api/categories/{id}",
        tags: ["Categories"],
        summary: "Afficher une catégorie"
    )]
    #[OA\Parameter(
        name: "id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer")
    )]
    #[OA\Response(response: 200, description: "Succès")]
    #[OA\Response(response: 404, description: "Catégorie introuvable")]
    public function show(int $id): JsonResponse
    {
        $category = $this->categoryService->findById($id);

        if (!$category) {
            return response()->json([
                'success' => false,
                'message' => 'Catégorie introuvable'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $category
        ]);
    }
}