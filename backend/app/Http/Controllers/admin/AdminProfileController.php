<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\GetAdminProfileRequest;
use App\Http\Resources\AdminProfileResource;
use App\Services\Interface\AdminProfileServiceInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;
use Symfony\Component\HttpFoundation\Response;
use Exception;

class AdminProfileController extends Controller
{
    public function __construct(
        protected AdminProfileServiceInterface $adminProfileService
    ) {
    }

    #[OA\Get(
        path: "/api/admin/profile",
        summary: "Afficher le profil de l'administrateur connecté",
        tags: ["Admin Profile"],
        security: [["bearerAuth" => []]],
        responses: [
            new OA\Response(response: 200, description: "Profil récupéré avec succès"),
            new OA\Response(response: 401, description: "Utilisateur non authentifié"),
            new OA\Response(response: 404, description: "Profil introuvable"),
        ]
    )]
    public function show(GetAdminProfileRequest $request): JsonResponse
    {
        try {
            // PublicID récupéré depuis le middleware JWT
            $publicId = $request->attributes->get('user_id');

            if (!$publicId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié.',
                ], Response::HTTP_UNAUTHORIZED);
            }

            $profile = $this->adminProfileService->getAdminProfile($publicId);

            return (new AdminProfileResource($profile))
                ->response()
                ->setStatusCode(Response::HTTP_OK);

        } catch (ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], Response::HTTP_NOT_FOUND);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la récupération du profil.',
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }
}