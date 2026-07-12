<?php

namespace App\Http\Controllers;

use App\Services\Interface\AdminServiceInterface;
use App\DTOs\Admin\CreateAdminDto;
use App\Http\Requests\Admin\CreateAdminRequest;
use App\Http\Resources\UserResource;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Administration",
    description: "Actions réservées aux administrateurs système"
)]
class AdminController extends Controller
{
    public function __construct(private AdminServiceInterface $adminService)
    {
    }

    #[OA\Post(
        path: "/api/admin/users",
        summary: "Ajouter un nouvel administrateur",
        description: "Permet à un admin existant de créer un nouveau compte administrateur.",
        tags: ["Administration"],
        security: [["bearerAuth" => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["first_name", "last_name", "email", "password"],
                properties: [
                    new OA\Property(property: "first_name", type: "string", example: "Jean"),
                    new OA\Property(property: "last_name", type: "string", example: "Dupont"),
                    new OA\Property(property: "email", type: "string", format: "email", example: "j.dupont@company.com"),
                    new OA\Property(property: "password", type: "string", format: "password", example: "Secret123*"),
                    new OA\Property(property: "phone_number", type: "string", example: "+33612345678")
                ]
            )
        )
    )]
    #[OA\Response(response: 201, description: "Nouvel administrateur créé avec succès")]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès interdit - Droits Admin requis")]
    #[OA\Response(response: 422, description: "Données de validation invalides (ex: Email déjà pris)")]
    public function store(CreateAdminRequest $request)
    {
            dd('OK');

        $dto = CreateAdminDto::fromArray($request->validated());

        $admin = $this->adminService->registerAdmin($dto);

        return (new UserResource($admin))
            ->response()
            ->setStatusCode(201);
    }
}