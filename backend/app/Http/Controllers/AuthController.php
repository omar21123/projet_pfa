<?php

namespace App\Http\Controllers;

use App\DTOs\Auth\LoginDto;
use App\DTOs\Auth\RegisterDto;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Services\AccessTokenService;
use App\Services\Interface\AuthServiceInterface;
use App\Services\RefreshTokenService;
use App\Services\UserService;
use App\Http\Requests\Auth\CustomerRegisterRequest;
use OpenApi\Attributes as OA;
use Illuminate\Validation\ValidationException;

#[OA\Tag(
    name: "Auth",
    description: "Authentification et création de compte"
)]
class AuthController extends Controller
{
    public function __construct(private AuthServiceInterface $authService , private AccessTokenService $accessTokenService,
        private RefreshTokenService $refreshTokenService,private UserService $userService)
    {
       
    }

 #[OA\Post(
    path: "/api/auth/mobile/register",
    tags: ["Auth"],
    summary: "Créer un compte client",
    description: "Création d'un compte client avec génération d'un utilisateur, profil client et refresh token.",
    requestBody: new OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: [
                "first_name",
                "last_name",
                "email",
                "password"
            ],
            properties: [
                new OA\Property(
                    property: "first_name",
                    type: "string",
                    example: "Mohammed"
                ),
                new OA\Property(
                    property: "last_name",
                    type: "string",
                    example: "Bourass"
                ),
                new OA\Property(
                    property: "email",
                    type: "string",
                    format: "email",
                    example: "mohammed@example.com"
                ),
                new OA\Property(
                    property: "password",
                    type: "string",
                    format: "password",
                    example: "Password123!"
                ),
                new OA\Property(
                    property: "phone_number",
                    type: "string",
                    nullable: true,
                    example: "+212612345678"
                ),
                new OA\Property(
                    property: "birth_date",
                    type: "string",
                    format: "date",
                    nullable: true,
                    example: "2002-05-15"
                ),
                new OA\Property(
                    property: "gender",
                    type: "integer",
                    nullable: true,
                    example: 1,
                    description: "1: Male, 2: Female"
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
    description: "Compte créé avec succès",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(
                property: "message",
                type: "string",
                example: "Compte créé avec succès."
            ),
            new OA\Property(
                property: "access_token",
                type: "string",
                example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
            ),
            new OA\Property(
                property: "Refresh_token",
                type: "string",
                example: "c8f5a2d4ae9b12..."
            ),
            new OA\Property(
                property: "displayName",
                type: "string",
                example: "Mohammed Bourass"
            ),
            new OA\Property(
                property: "verify_email",
                type: "boolean",
                example: false
            ),
            new OA\Property(
                property: "verify_phone",
                type: "boolean",
                example: false
            ),
            new OA\Property(
                property: "public_id",
                type: "string",
                example: "550e8400-e29b-41d4-a716-446655440000"
            )
        ]
    )
)]
#[OA\Response(
    response: 422,
    description: "Erreur de validation",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(
                property: "message",
                type: "string",
                example: "The given data was invalid."
            ),
            new OA\Property(
                property: "errors",
                type: "object",
                example: [
                    "email" => [
                        "Cet email existe déjà."
                    ]
                ]
            )
        ]
    )
)]
public function Customerregister(CustomerRegisterRequest $request)
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
  

    $dto = RegisterDto::fromArray($data);

    $refreshToken = $this->refreshTokenService->generate();

    $publicId = $this->authService->createCustomer(
        $dto,
        $refreshToken['token_hash'],
        request()->ip(),
        (int) env('JWT_REFRESH_TTL', 2592000)
    );
    $accessToken = $this->accessTokenService->generate($publicId ,'CUSTOMER');
    return response()->json([
        'message' => 'Compte créé avec succès.',
        'access_token' => $accessToken,
         'unreadNotifications' => 0,
        'Refresh_token' => $refreshToken['token'],
        'displayName' => $dto->firstName . ' ' . $dto->lastName,
        'verify_email' => false,
        'verify_phone' => false,
        'public_id' => $publicId,
    ], 201);
}
 #[OA\Post(
    path: "/api/auth/web/customer/register",
    tags: ["Auth"],
    summary: "Créer un compte client (Web)",
    description: "Création d'un compte client avec génération d'un utilisateur et d'un profil client. Le refresh token est stocké dans un cookie HttpOnly sécurisé et n'est pas retourné dans le corps de la réponse.",
    requestBody: new OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: [
                "first_name",
                "last_name",
                "email",
                "password"
            ],
            properties: [
                new OA\Property(property: "first_name", type: "string", example: "Mohammed"),
                new OA\Property(property: "last_name", type: "string", example: "Bourass"),
                new OA\Property(property: "email", type: "string", format: "email", example: "mohammed@example.com"),
                new OA\Property(property: "password", type: "string", format: "password", example: "Password123!"),
                new OA\Property(property: "phone_number", type: "string", nullable: true, example: "+212612345678"),
                new OA\Property(property: "birth_date", type: "string", format: "date", nullable: true, example: "2002-05-15"),
                new OA\Property(
                    property: "gender",
                    type: "integer",
                    nullable: true,
                    example: 1,
                    description: "1: Male, 2: Female"
                ),
                new OA\Property(property: "avatar_url", type: "string", nullable: true, example: "https://example.com/avatar.png")
            ]
        )
    )
)]
#[OA\Response(
    response: 201,
    description: "Compte créé avec succès. Le refresh token est défini via un cookie HttpOnly (non présent dans le corps de la réponse).",
    headers: [
        new OA\Header(
            header: "Set-Cookie",
            description: "Cookie HttpOnly, Secure, SameSite=Strict contenant le refresh token.",
            schema: new OA\Schema(
                type: "string",
                example: "refresh_token=c8f5a2d4ae9b12...; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=2592000"
            )
        )
    ],
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "message", type: "string", example: "Compte créé avec succès."),
            new OA\Property(property: "access_token", type: "string", example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."),
            new OA\Property(property: "displayName", type: "string", example: "Mohammed Bourass"),
            new OA\Property(property: "verify_email", type: "boolean", example: false),
            new OA\Property(property: "verify_phone", type: "boolean", example: false),
            new OA\Property(property: "public_id", type: "string", example: "550e8400-e29b-41d4-a716-446655440000")
        ]
    )
)]
#[OA\Response(
    response: 422,
    description: "Erreur de validation",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "message", type: "string", example: "The given data was invalid."),
            new OA\Property(
                property: "errors",
                type: "object",
                example: ["email" => ["Cet email existe déjà."]]
            )
        ]
    )
)]
public function CustomerRegisterWeb(CustomerRegisterRequest $request)
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

    $dto = RegisterDto::fromArray($data);

    $refreshToken = $this->refreshTokenService->generate();

    $ttlSeconds = (int) env('JWT_REFRESH_TTL', 2592000);

    $publicId = $this->authService->createCustomer(
        $dto,
        $refreshToken['token_hash'],
        request()->ip(),
        $ttlSeconds
    );

    $accessToken = $this->accessTokenService->generate($publicId, 'CUSTOMER');

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
        'message' => 'Compte créé avec succès.',
        'access_token' => $accessToken,
        'unreadNotifications' => 0,
        'displayName' => $dto->firstName . ' ' . $dto->lastName,
        'verify_email' => false,
        'verify_phone' => false,
        'public_id' => $publicId,
    ], 201)->withCookie($refreshCookie);
}


    #[OA\Post(
        path: "/api/auth/mobile/login",
        tags: ["Auth"],
        summary: "Connexion utilisateur",
        description: "Authentification d'un client avec email et mot de passe. Retourne un access token et un refresh token.",
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
    #[OA\Response(
        response: 201,
        description: "Connexion réussie",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Connexion réussie."),
                new OA\Property(property: "access_token", type: "string", example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."),
                new OA\Property(property: "unreadNotifications", type: "integer", example: 0),
                new OA\Property(property: "Refresh_token", type: "string", example: "c8f5a2d4ae9b12..."),
                new OA\Property(property: "displayName", type: "string", example: "Mohammed Bourass"),
                new OA\Property(property: "verify_email", type: "boolean", example: false),
                new OA\Property(property: "verify_phone", type: "boolean", example: false),
                new OA\Property(property: "public_id", type: "string", example: "550e8400-e29b-41d4-a716-446655440000"),
            ]
        )
    )]
    #[OA\Response(
        response: 401,
        description: "Identifiants invalides",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Identifiants invalides.")
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Erreur de validation",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "The given data was invalid."),
                new OA\Property(property: "errors", type: "object", example: ["email" => ["L'email est requis."], "password" => ["Le mot de passe est requis."]])
            ]
        )
    )]
    public function login(LoginRequest $request)
    {
        $data = $request->validated();
        $dto = LoginDto::fromArray($request->validated());
         if (!$this->userService->emailExists($data['email'])) {
          throw ValidationException::withMessages([
                'email' => ['Identifiants invalides.'],
            ]);
         }
        $result = $this->authService->login($dto);
        $this->userService->updateLastLogin($result->userId);
        $refreshToken = $this->refreshTokenService->generate();
        $accessToken = $this->accessTokenService->generate($result->publicId, 'CUSTOMER');
        $ttlSeconds = (int) env('JWT_REFRESH_TTL', 2592000);
        $this->userService->createRefreshToken(
            $result->userId,
            $refreshToken['token_hash'],
            request()->ip(),
            $ttlSeconds
        );
        $unreadNotificationsCount = $this->userService->getReadNotificationsCount($result->userId);
         return response()->json([
        'message' => 'Connexion réussie.',
        'access_token' => $accessToken,
         'unreadNotifications' => $unreadNotificationsCount,
        'Refresh_token' => $refreshToken['token'],
        'displayName' => $result->displayName,
        'verify_email' => $result->emailVerified,
        'verify_phone' => $result->phoneVerified,
        'public_id' => $result->publicId,
    ], 201);
    }
    #[OA\Post(
    path: "/api/auth/web/login",
    tags: ["Auth"],
    summary: "Connexion utilisateur (Web)",
    description: "Authentification d'un client avec email et mot de passe. Retourne un access token dans le body et un refresh token dans un cookie HttpOnly.",
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
#[OA\Response(
    response: 201,
    description: "Connexion réussie",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "message", type: "string", example: "Connexion réussie."),
            new OA\Property(property: "access_token", type: "string", example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."),
            new OA\Property(property: "unreadNotifications", type: "integer", example: 0),
            new OA\Property(property: "displayName", type: "string", example: "Mohammed Bourass"),
            new OA\Property(property: "verify_email", type: "boolean", example: false),
            new OA\Property(property: "verify_phone", type: "boolean", example: false),
            new OA\Property(property: "public_id", type: "string", example: "550e8400-e29b-41d4-a716-446655440000"),
        ]
    )
)]
#[OA\Response(
    response: 401,
    description: "Identifiants invalides",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "message", type: "string", example: "Identifiants invalides.")
        ]
    )
)]
#[OA\Response(
    response: 422,
    description: "Erreur de validation",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "message", type: "string", example: "The given data was invalid."),
            new OA\Property(property: "errors", type: "object", example: ["email" => ["L'email est requis."], "password" => ["Le mot de passe est requis."]])
        ]
    )
)]
public function webLogin(LoginRequest $request)
{
    $data = $request->validated();
    $dto = LoginDto::fromArray($request->validated());

    if (!$this->userService->emailExists($data['email'])) {
        throw ValidationException::withMessages([
            'email' => ['Identifiants invalides.'],
        ]);
    }

    $result = $this->authService->login($dto);
    $this->userService->updateLastLogin($result->userId);

    $refreshToken = $this->refreshTokenService->generate();
    $accessToken = $this->accessTokenService->generate($result->publicId, 'CUSTOMER');

    $ttlSeconds = (int) env('JWT_REFRESH_TTL', 2592000);

    $this->userService->createRefreshToken(
        $result->userId,
        $refreshToken['token_hash'],
        request()->ip(),
        $ttlSeconds
    );

    $unreadNotificationsCount = $this->userService->getReadNotificationsCount($result->userId);

    // Laravel's cookie() helper expects minutes, not seconds
    $refreshCookie = cookie(
        'refresh_token',            // name
        $refreshToken['token'],     // value
        (int) ($ttlSeconds / 60),   // minutes
        '/',                        // path
        null,                       // domain (null = current domain)
        true,                       // secure (HTTPS only — keep true in prod)
        true,                       // httpOnly
        false,                      // raw
        'Strict'                    // sameSite
    );

    return response()->json([
        'message' => 'Connexion réussie.',
        'access_token' => $accessToken,
        'unreadNotifications' => $unreadNotificationsCount,
        'displayName' => $result->displayName,
        'verify_email' => $result->emailVerified,
        'verify_phone' => $result->phoneVerified,
        'public_id' => $result->publicId,
    ], 201)->withCookie($refreshCookie);
}
}