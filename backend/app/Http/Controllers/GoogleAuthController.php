<?php

namespace App\Http\Controllers;

use App\DTOs\Auth\CompleteGoogleProfileDto;
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
    description: "Authentification via Google OAuth (web + mobile) et gestion de l'onboarding"
)]
class GoogleAuthController extends Controller
{
    public function __construct(private AuthServiceInterface $googleAuthService)
    {
    }

    /* =======================================================================
     * FLOW WEB — REDIRECTION NAVIGATEUR (routes/web.php)
     * ======================================================================= */

    /**
     * Étape 1 : Redirige l'utilisateur vers Google.
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

        // Si l'utilisateur doit choisir son rôle, on le redirige vers la page d'onboarding
        $redirectUrl = $result['requires_onboarding']
            ? rtrim(env('FRONTEND_URL', ''), '/') . '/complete-profile?access_token=' . urlencode($result['access_token'])
            : rtrim(env('FRONTEND_URL', ''), '/') . '/auth/callback?access_token=' . urlencode($result['access_token']);

        return redirect($redirectUrl)->withCookie($refreshCookie);
    }

    /* =======================================================================
     * FLOW MOBILE — id_token dans le body (routes/api.php)
     * ======================================================================= */

    #[OA\Post(
        path: "/api/auth/mobile/google",
        tags: ["Auth - Google"],
        summary: "Connexion / inscription via Google (mobile)",
        description: "L'app mobile envoie l'ID token obtenu via le SDK Google Sign-In. Le backend retourne access_token + refresh_token ainsi que le statut d'onboarding.",
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
                new OA\Property(property: "role", type: "string", nullable: true, example: "CUSTOMER"),
                new OA\Property(property: "is_new_user", type: "boolean"),
                new OA\Property(property: "requires_onboarding", type: "boolean", example: true),
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
            'role' => $loginResult['role'],
            'is_new_user' => $loginResult['is_new_user'],
            'requires_onboarding' => $loginResult['requires_onboarding'],
        ], 201);
    }

    /* =======================================================================
     * FLOW WEB — id_token via Google Identity Services (routes/api.php)
     * ======================================================================= */

    #[OA\Post(
        path: "/api/auth/web/google",
        tags: ["Auth - Google"],
        summary: "Connexion / inscription via Google (Web)",
        description: "Le frontend envoie l'ID Token Google. Le backend retourne access_token et définit le cookie HttpOnly pour le refresh_token.",
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
        headers: [
            new OA\Header(
                header: "Set-Cookie",
                description: "Cookie HttpOnly contenant le refresh_token.",
                schema: new OA\Schema(type: "string")
            )
        ],
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Connexion réussie."),
                new OA\Property(property: "access_token", type: "string"),
                new OA\Property(property: "unreadNotifications", type: "integer", example: 0),
                new OA\Property(property: "displayName", type: "string", example: "Mohammed Bourass"),
                new OA\Property(property: "email", type: "string", example: "user@gmail.com"),
                new OA\Property(property: "public_id", type: "string"),
                new OA\Property(property: "role", type: "string", nullable: true, example: null),
                new OA\Property(property: "is_new_user", type: "boolean", example: true),
                new OA\Property(property: "requires_onboarding", type: "boolean", example: true),
            ]
        )
    )]
    #[OA\Response(response: 401, description: "ID token Google invalide")]
    // app/Http/Controllers/GoogleAuthController.php

    public function webGoogleLogin(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id_token' => ['required', 'string'],
            'role' => ['nullable', 'string', 'in:CUSTOMER,VENDOR,customer,vendor'],
            'store_name' => ['required_if:role,VENDOR,vendor', 'nullable', 'string', 'max:100'],
            'phone_number' => ['nullable', 'string', 'max:20'],
            'birth_date' => ['nullable', 'date'],
            'gender' => ['nullable', 'integer', 'in:1,2'],
            'description' => ['nullable', 'string', 'max:1000'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Les données fournies sont invalides.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $dto = $this->verifyGoogleIdToken($request->input('id_token'));

        if (!$dto) {
            return response()->json(['message' => 'ID token Google invalide.'], 401);
        }

        $ttlSeconds = (int) env('JWT_REFRESH_TTL', 2592000);

        // On passe l'ensemble des champs validés à AuthService
        $loginResult = $this->googleAuthService->loginOrRegister(
            $dto,
            $request->ip(),
            $ttlSeconds,
            $validator->validated() // 👈 Transférer les données du formulaire (role, store_name, etc.)
        );

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
            'role' => $loginResult['role'],
            'is_new_user' => $loginResult['is_new_user'],
            'requires_onboarding' => $loginResult['requires_onboarding'],
        ], 201)->withCookie($refreshCookie);
    }

    /* =======================================================================
     * FINALISATION DU PROFIL (ONBOARDING : CHOIX DU RÔLE ET INFOS)
     * ======================================================================= */

    #[OA\Post(
        path: "/api/auth/google/complete-profile",
        tags: ["Auth - Google"],
        summary: "Finaliser l'inscription Google (Rôle et Infos)",
        description: "Appelé après la connexion Google si requires_onboarding = true. Permet de choisir le rôle (CUSTOMER/VENDOR) et d'ajouter le numéro de téléphone, date de naissance ou nom de boutique.",
        security: [["bearerAuth" => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["role"],
                properties: [
                    new OA\Property(property: "role", type: "string", enum: ["CUSTOMER", "VENDOR"], example: "VENDOR"),
                    new OA\Property(property: "phone_number", type: "string", nullable: true, example: "+212600000000"),
                    new OA\Property(property: "birth_date", type: "string", format: "date", nullable: true, example: "1995-05-20"),
                    new OA\Property(property: "gender", type: "integer", enum: [1, 2], nullable: true, example: 1),
                    new OA\Property(property: "store_name", type: "string", nullable: true, example: "Boutique Tech"),
                    new OA\Property(property: "description", type: "string", nullable: true, example: "Magasin d'électronique"),
                ]
            )
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Profil finalisé et rôle attribué avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Profil finalisé avec succès."),
                new OA\Property(property: "access_token", type: "string"),
                new OA\Property(property: "role", type: "string", example: "VENDOR"),
                new OA\Property(property: "public_id", type: "string"),
                new OA\Property(property: "requires_onboarding", type: "boolean", example: false),
            ]
        )
    )]
    #[OA\Response(response: 422, description: "Données invalides ou nom de boutique manquant")]
    public function completeProfile(Request $request)
    {
        // 1. Normaliser le rôle en majuscules dès le début
        if ($request->has('role')) {
            $request->merge(['role' => strtoupper($request->role)]);
        }

        // 2. Validation
        $validator = Validator::make($request->all(), [
            'role' => ['required', 'string', 'in:CUSTOMER,VENDOR'],
            'phone_number' => ['nullable', 'string', 'max:20'],
            'birth_date' => ['nullable', 'date'],
            'gender' => ['nullable', 'integer', 'in:1,2'],
            'store_name' => ['required_if:role,VENDOR', 'nullable', 'string', 'max:100'],
            'description' => ['nullable', 'string', 'max:1000'],
            'google_token' => ['nullable', 'string'],
            'id_token' => ['nullable', 'string'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Les données fournies sont invalides.',
                'errors' => $validator->errors(),
            ], 422);
        }

        // 3. Récupération robuste de l'utilisateur
        $userId = $request->attributes->get('user_id')
            ?? $request->user()?->UserID
            ?? auth()->id();

        // Secours : Si non authentifié via Header Bearer, vérifier via le token Google envoyé dans le body
        if (!$userId && ($request->filled('google_token') || $request->filled('id_token'))) {
            $token = $request->input('google_token') ?? $request->input('id_token');
            // Optionnel : résoudre l'utilisateur via votre service Google si nécessaire
            // $user = $this->googleAuthService->findUserByGoogleToken($token);
            // $userId = $user?->UserID;
        }

        if (!$userId) {
            return response()->json([
                'message' => 'Non autorisé. Jeton de session manquant ou expiré.'
            ], 401);
        }

        $dto = CompleteGoogleProfileDto::fromArray($validator->validated());

        try {
            $result = $this->googleAuthService->completeGoogleProfile($userId, $dto);
            return response()->json([
                'message' => 'Profil finalisé avec succès.',
                'access_token' => $result['access_token'] ?? null,
                'role' => $result['role'] ?? $request->role,
                'public_id' => $result['user']->publicId ?? $result['user']->public_id ?? null,
                'requires_onboarding' => false,
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Erreur lors de la mise à jour du profil.',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Throwable $e) {
            // Capturer toutes les autres exceptions système
            \Log::error('Erreur completeProfile: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'message' => 'Une erreur interne est survenue lors de la finalisation du profil.',
                'error' => config('app.debug') ? $e->getMessage() : 'Erreur serveur'
            ], 500);
        }
    }

    /* =======================================================================
     * MÉTHODES PRIVÉES DE VALIDATION DU TOKEN GOOGLE
     * ======================================================================= */

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

    private function verifyGoogleIdToken(string $idToken): ?GoogleUserDto
    {
        $response = Http::get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $idToken,
        ]);

        if (!$response->ok()) {
            return null;
        }

        $payload = $response->json();

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