<?php

namespace App\Http\Controllers;

use App\DTOs\Auth\GoogleUserDto;
use App\Http\Controllers\Controller;
use App\Services\Interface\AuthServiceInterface;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;
use Laravel\Socialite\Facades\Socialite;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Auth - Google",
    description: "Authentification via Google OAuth (web + mobile)"
)]
class GoogleAuthController extends Controller
{
    public function __construct(private AuthServiceInterface $googleAuthService) {}

    /* =======================================================================
     * FLOW WEB — redirection navigateur (routes/web.php, PAS api.php)
     * ======================================================================= */

    /**
     * Étape 1 : redirige l'utilisateur vers Google.
     * GET /auth/google
     */
    public function redirectToGoogle()
    {
        return Socialite::driver('google')->redirect();
    }

    /**
     * Étape 2 : Google redirige ici après authentification.
     * GET /auth/google/callback
     */
    public function handleGoogleCallback(Request $request)
    {
        try {
            $googleUser = Socialite::driver('google')->stateless()->user();
        } catch (\Throwable $e) {
            return redirect(rtrim(env('FRONTEND_URL', ''), '/') . '/login?error=google_auth_failed');
        }

        $dto = GoogleUserDto::fromSocialite($googleUser);
        $ttlSeconds = (int) env('JWT_REFRESH_TTL', 2592000);

        $result = $this->googleAuthService->loginOrRegister($dto, $request->ip(), $ttlSeconds);

        $refreshCookie = cookie(
            'refresh_token',
            $result['refresh_token'],
            (int) ($ttlSeconds / 60),
            '/',
            null,
            true,
            true,
            false,
            'Strict'
        );

        // Redirige vers le frontend avec l'access_token en query param.
        // Le refresh_token, lui, part dans un cookie HttpOnly (pas dans l'URL).
        return redirect(
            rtrim(env('FRONTEND_URL', ''), '/') . '/auth/callback?access_token=' . urlencode($result['access_token'])
        )->withCookie($refreshCookie);
    }

    /* =======================================================================
     * FLOW MOBILE / SPA — le client envoie directement l'id_token Google
     * (routes/api.php, comme tes autres endpoints /mobile/... et /web/...)
     * ======================================================================= */

    #[OA\Post(
        path: "/api/auth/mobile/google",
        tags: ["Auth - Google"],
        summary: "Connexion / inscription via Google (mobile)",
        description: "L'app mobile envoie l'ID token obtenu via le SDK Google Sign-In. Le backend le vérifie auprès de Google puis retourne access_token + refresh_token dans le body.",
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["id_token"],
                properties: [
                    new OA\Property(property: "id_token", type: "string", example: "eyJhbGciOiJSUzI1NiIsImtpZCI6..."),
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
                new OA\Property(property: "access_token", type: "string"),
                new OA\Property(property: "Refresh_token", type: "string"),
                new OA\Property(property: "displayName", type: "string"),
                new OA\Property(property: "public_id", type: "string"),
                new OA\Property(property: "is_new_user", type: "boolean"),
            ]
        )
    )]
    #[OA\Response(response: 401, description: "ID token Google invalide")]
    public function mobileGoogleLogin(Request $request)
    {
        $result = $this->handleIdToken($request);

        if ($result instanceof \Illuminate\Http\JsonResponse) {
            return $result;
        }

        [$dto, $loginResult] = $result;

        return response()->json([
            'message' => 'Connexion réussie.',
            'access_token' => $loginResult['access_token'],
            'unreadNotifications' => 0,
            'Refresh_token' => $loginResult['refresh_token'],
            'displayName' => trim($dto->firstName . ' ' . $dto->lastName),
            'public_id' => $loginResult['user']->publicId,
            'is_new_user' => $loginResult['is_new_user'],
        ], 201);
    }

   #[OA\Post(
    path: "/api/auth/web/google",
    tags: ["Auth - Google"],
    summary: "Connexion / inscription via Google (Web)",
    description: "Le frontend envoie l'ID Token Google obtenu via Google Identity Services. Le backend vérifie ce token auprès de Google, authentifie ou crée l'utilisateur puis retourne un access_token. Le refresh_token est envoyé dans un cookie HttpOnly sécurisé.",
    requestBody: new OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["id_token"],
            properties: [
                new OA\Property(
                    property: "id_token",
                    type: "string",
                    example: "eyJhbGciOiJSUzI1NiIsImtpZCI6..."
                ),
            ]
        )
    )
)]
#[OA\Response(
    response: 201,
    description: "Connexion réussie",
    headers: [
        new OA\Header(
            header: "Set-Cookie",
            description: "Cookie HttpOnly contenant le refresh_token.",
            schema: new OA\Schema(
                type: "string",
                example: "refresh_token=xxxxxxxx; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=2592000"
            )
        )
    ],
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "message", type: "string", example: "Connexion réussie."),
            new OA\Property(property: "access_token", type: "string"),
            new OA\Property(property: "unreadNotifications", type: "integer", example: 0),
            new OA\Property(property: "displayName", type: "string", example: "Mohammed Bourass"),
            new OA\Property(property: "public_id", type: "string"),
            new OA\Property(property: "role", type: "string", example: "CUSTOMER"),
            new OA\Property(property: "is_new_user", type: "boolean", example: false),
        ]
    )
)]
#[OA\Response(
    response: 401,
    description: "ID token Google invalide"
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
                example: [
                    "id_token" => [
                        "The id token field is required."
                    ]
                ]
            )
        ]
    )
)]

    public function webGoogleLogin(Request $request)
    {
        $result = $this->handleIdToken($request);

        if ($result instanceof \Illuminate\Http\JsonResponse) {
            return $result;
        }

        [$dto, $loginResult] = $result;

        $ttlSeconds = (int) env('JWT_REFRESH_TTL', 2592000);

        $refreshCookie = cookie(
            'refresh_token',
            $loginResult['refresh_token'],
            (int) ($ttlSeconds / 60),
            '/',
            null,
            true,
            true,
            false,
            'Strict'
        );

        return response()->json([
            'message' => 'Connexion réussie.',
            'access_token' => $loginResult['access_token'],
            'unreadNotifications' => 0,
            'displayName' => trim($dto->firstName . ' ' . $dto->lastName),
            'email' => $dto->email,
            'public_id' => $loginResult['user']->publicId,
            'role' => 'CUSTOMER',
            'is_new_user' => $loginResult['is_new_user'],
        ], 201)->withCookie($refreshCookie);
    }

    /**
     * Valide la requête + vérifie l'id_token, factorisé pour mobile/web.
     * Retourne soit une JsonResponse d'erreur, soit [GoogleUserDto, resultArray].
     */
    private function handleIdToken(Request $request): \Illuminate\Http\JsonResponse|array
    {
        $validator = Validator::make($request->all(), [
            'id_token' => ['required', 'string'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'The given data was invalid.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $dto = $this->verifyGoogleIdToken($request->input('id_token'));

        if (!$dto) {
            return response()->json(['message' => 'ID token Google invalide.'], 401);
        }

        $ttlSeconds = (int) env('JWT_REFRESH_TTL', 2592000);
        $loginResult = $this->googleAuthService->loginOrRegister($dto, $request->ip(), $ttlSeconds);

        return [$dto, $loginResult];
    }

    /**
     * Vérifie l'id_token directement auprès de Google (endpoint tokeninfo).
     * Simple et sans dépendance lourde (pas besoin de google/apiclient).
     * Vérifie aussi que le token a bien été émis pour TON client_id (aud).
     */
    private function verifyGoogleIdToken(string $idToken): ?GoogleUserDto
    {
        $response = Http::get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $idToken,
        ]);

        if (!$response->ok()) {
            return null;
        }

        $payload = $response->json();

        // Autorise plusieurs client_id (web, Android, iOS) si besoin
        $validAudiences = array_filter([
            env('GOOGLE_CLIENT_ID'),
            env('GOOGLE_CLIENT_ID_ANDROID'),
            env('GOOGLE_CLIENT_ID_IOS'),
        ]);

        if (empty($payload['sub']) || empty($payload['email'])) {
            return null;
        }

        if (!in_array($payload['aud'] ?? null, $validAudiences, true)) {
            return null;
        }

        return GoogleUserDto::fromTokenInfo($payload);
    }
}