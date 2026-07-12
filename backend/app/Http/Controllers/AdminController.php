<?php

namespace App\Http\Controllers;

use App\Services\Interface\AdminServiceInterface;
use App\Services\AccessTokenService;
use App\Services\RefreshTokenService;
use App\Services\UserService;
use App\DTOs\Admin\CreateAdminDto;
use App\Http\Requests\Admin\CreateAdminRequest;
use OpenApi\Attributes as OA;
use Illuminate\Validation\ValidationException;

#[OA\Tag(
    name: "Administration",
    description: "Actions réservées aux administrateurs système"
)]
class AdminController extends Controller
{
    public function __construct(
        private AdminServiceInterface $adminService,
        private UserService $userService,
        private RefreshTokenService $refreshTokenService,
        private AccessTokenService $accessTokenService
    ) {
    }

 #[OA\Post(
    path: "/api/admin/register",
    tags: ["Administration"],
    summary: "Ajouter un nouvel administrateur",
    description: "Permet à un admin existant de créer un nouveau compte administrateur. "
        . "Le hash du mot de passe, le token de rafraîchissement, l'adresse IP et la durée de vie (TTL) "
        . "sont générés/déterminés côté serveur et ne font pas partie du corps de la requête.",
    security: [["bearerAuth" => []]],
    requestBody: new OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["first_name", "last_name", "email", "password"],
            properties: [
                new OA\Property(
                    property: "first_name",
                    type: "string",
                    maxLength: 100,
                    example: "Jean"
                ),
                new OA\Property(
                    property: "last_name",
                    type: "string",
                    maxLength: 100,
                    example: "Dupont"
                ),
                new OA\Property(
                    property: "email",
                    type: "string",
                    format: "email",
                    maxLength: 255,
                    example: "j.dupont@company.com"
                ),
                new OA\Property(
                    property: "password",
                    type: "string",
                    format: "password",
                    minLength: 8,
                    example: "Secret123*"
                ),
                new OA\Property(
                    property: "phone_number",
                    type: "string",
                    nullable: true,
                    maxLength: 30,
                    example: "+33612345678"
                ),
                new OA\Property(
                    property: "birth_date",
                    type: "string",
                    format: "date",
                    nullable: true,
                    example: "1990-04-12"
                ),
                new OA\Property(
                    property: "gender",
                    type: "integer",
                    nullable: true,
                    example: 1,
                    description: "1: Male, 2: Female"
                ),
                new OA\Property(
                    property: "cin",
                    type: "string",
                    nullable: true,
                    maxLength: 30,
                    example: "AB123456",
                    description: "Carte d'identité nationale"
                ),
                new OA\Property(
                    property: "employee_number",
                    type: "string",
                    nullable: true,
                    maxLength: 30,
                    example: "EMP-0042"
                ),
                new OA\Property(
                    property: "position",
                    type: "string",
                    nullable: true,
                    maxLength: 30,
                    example: "Support Manager"
                ),
                new OA\Property(
                    property: "hire_date",
                    type: "string",
                    format: "date-time",
                    nullable: true,
                    example: "2026-07-12 09:00:00",
                    description: "Défaut : date/heure actuelle si non fournie."
                ),
                new OA\Property(
                    property: "avatar_url",
                    type: "string",
                    nullable: true,
                    example: "https://example.com/avatar.png"
                )
            ]
        )
    )
)]
#[OA\Response(
    response: 201,
    description: "Nouvel administrateur créé avec succès.",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "message", type: "string", example: "Administrateur créé avec succès."),
            new OA\Property(property: "access_token", type: "string", example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."),
            new OA\Property(property: "refresh_token", type: "string", example: "c8f5a2d4ae9b12..."),
            new OA\Property(property: "displayName", type: "string", example: "Jean Dupont"),
            new OA\Property(property: "role", type: "string", example: "ADMIN"),
            new OA\Property(property: "public_id", type: "string", example: "550e8400-e29b-41d4-a716-446655440000"),
        ]
    )
)]
#[OA\Response(
    response: 401,
    description: "Non authentifié.",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "message", type: "string", example: "Non authentifié.")
        ]
    )
)]
#[OA\Response(
    response: 403,
    description: "Accès interdit - Droits Admin requis.",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "message", type: "string", example: "Accès interdit.")
        ]
    )
)]
#[OA\Response(
    response: 422,
    description: "Erreur de validation (ex: Email ou téléphone déjà pris).",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "message", type: "string", example: "The given data was invalid."),
            new OA\Property(
                property: "errors",
                type: "object",
                example: [
                    "email" => ["Cet email existe déjà."],
                    "phone_number" => ["Ce numéro existe déjà."]
                ]
            )
        ]
    )
)]
#[OA\Response(
    response: 500,
    description: "Erreur serveur lors de la création du compte administrateur.",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "message", type: "string", example: "Impossible de créer le compte administrateur.")
        ]
    )
)]
    public function store(CreateAdminRequest $request)
    {
        $data = $request->validated();

        if ($this->userService->emailExists($data['email'])) {
            throw ValidationException::withMessages([
                'email' => ['Cet email existe déjà.'],
            ]);
        }

        if (!empty($data['phone_number']) &&
            $this->userService->phoneNumberExists($data['phone_number'])) {

            throw ValidationException::withMessages([
                'phone_number' => ['Ce numéro existe déjà.'],
            ]);
        }

        $dto = CreateAdminDto::fromArray($data);

        $refreshToken = $this->refreshTokenService->generate();
        $ttlSeconds = (int) env('JWT_REFRESH_TTL', 2592000);

        $publicId = $this->adminService->registerAdmin(
            $dto,
            $refreshToken['token_hash'],
            $request->ip(),
            $ttlSeconds
        );

        $accessToken = $this->accessTokenService->generate($publicId, 'ADMIN');
            // Laravel's cookie() helper expects minutes, not seconds
    $refreshCookie = cookie(
        'refresh_token',   // name
        $refreshToken['token'], // value
        (int) ($ttlSeconds / 60), // minutes
        '/',                // path
        null,                // domain (null = current domain)
        true,                // secure (HTTPS only — keep true in prod)
        true,                // httpOnly
        false,               // raw
        'Strict'             // sameSite
    );

        return response()->json([
            'message' => 'Administrateur créé avec succès.',
            'access_token' => $accessToken,
            'displayName' => $dto->firstName . ' ' . $dto->lastName,
            'role' => 'ADMIN',
            'public_id' => $publicId,
        ], 201)->withCookie($refreshCookie);
    }
}