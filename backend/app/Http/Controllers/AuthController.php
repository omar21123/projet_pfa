<?php

namespace App\Http\Controllers;

use App\DTOs\Auth\LoginDto;
use App\DTOs\Auth\RegisterDto;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Services\Interface\AuthServiceInterface;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Auth",
    description: "Authentification et création de compte"
)]
class AuthController extends Controller
{
    public function __construct(private AuthServiceInterface $authService)
    {
    }

    #[OA\Post(
        path: "/api/auth/register",
        tags: ["Auth"],
        summary: "Créer un compte utilisateur",
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["first_name", "last_name", "email", "password", "account_type"],
                properties: [
                    new OA\Property(property: "first_name", type: "string", example: "Ali"),
                    new OA\Property(property: "last_name", type: "string", example: "Benali"),
                    new OA\Property(property: "email", type: "string", format: "email", example: "ali@example.com"),
                    new OA\Property(property: "password", type: "string", format: "password", example: "Password123!"),
                    new OA\Property(property: "phone_number", type: "string", nullable: true, example: "+212600000000"),
                    new OA\Property(property: "birth_date", type: "string", format: "date", nullable: true, example: "1998-04-12"),
                    new OA\Property(property: "gender", type: "integer", nullable: true, example: 1),
                    new OA\Property(property: "account_type", type: "string", example: "customer"),
                    new OA\Property(property: "store_name", type: "string", nullable: true, example: "My Store"),
                    new OA\Property(property: "store_description", type: "string", nullable: true, example: "Boutique en ligne"),
                ]
            )
        )
    )]
    #[OA\Response(response: 201, description: "Compte créé avec succès")]
    public function register(RegisterRequest $request)
    {
        $dto = RegisterDto::fromArray($request->validated());

        $result = $this->authService->register($dto);

        return (new UserResource($result->user))
            ->additional(['token' => $result->token, 'token_type' => $result->tokenType])
            ->response()
            ->setStatusCode(201);
    }

    #[OA\Post(
        path: "/api/auth/login",
        tags: ["Auth"],
        summary: "Connexion utilisateur",
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["email", "password"],
                properties: [
                    new OA\Property(property: "email", type: "string", format: "email", example: "ali@example.com"),
                    new OA\Property(property: "password", type: "string", format: "password", example: "Password123!"),
                ]
            )
        )
    )]
    #[OA\Response(response: 200, description: "Connexion réussie")]
    public function login(LoginRequest $request)
    {
        $dto = LoginDto::fromArray($request->validated());

        $result = $this->authService->login($dto);

        return (new UserResource($result->user))
            ->additional(['token' => $result->token, 'token_type' => $result->tokenType]);
    }
}