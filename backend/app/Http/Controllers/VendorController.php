<?php

namespace App\Http\Controllers;

use App\Services\Interface\VendorServiceInterface;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Vendors",
    description: "Gestion des vendeurs"
)]
class VendorController extends Controller
{
    public function __construct(
        protected VendorServiceInterface $vendorService,
    ) {}

    #[OA\Get(
        path: "/api/vendors/{vendorProfileID}/public-profile",
        tags: ["Vendors"],
        summary: "Profil public d'un vendeur",
        description: "Retourne le profil public d'un vendeur : nom de boutique, logo, bannière, note/évaluations, statuts de vérification (identité, entreprise, banque), description, adresse, progression du profil, catégories de produits couvertes et statistiques (produits, ventes). Accessible aux invités."
    )]
    #[OA\Parameter(
        name: "vendorProfileID",
        in: "path",
        required: true,
        description: "Identifiant du profil vendeur.",
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 5
    )]
    #[OA\Response(
        response: 200,
        description: "Profil vendeur récupéré avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "StoreName", type: "string", example: "TechStore"),
                        new OA\Property(property: "LogoURL", type: "string", nullable: true, example: "https://cdn.example.com/logos/techstore.png"),
                        new OA\Property(property: "BannerURL", type: "string", nullable: true, example: "https://cdn.example.com/banners/techstore.png"),
                        new OA\Property(property: "Note", type: "string", example: "Excellent vendeur"),
                        new OA\Property(property: "Rating", type: "number", format: "float", example: 4.8),
                        new OA\Property(property: "ReviewCount", type: "integer", example: 320),
                        new OA\Property(property: "IdentityVerified", type: "boolean", example: true),
                        new OA\Property(property: "BusinessVerified", type: "boolean", example: true),
                        new OA\Property(property: "BankVerified", type: "boolean", example: false),
                        new OA\Property(property: "Description", type: "string", nullable: true, example: "Spécialiste en électronique depuis 2015."),
                        new OA\Property(property: "ApprovedAt", type: "string", format: "date-time", nullable: true),
                        new OA\Property(property: "ProfileProgress", type: "number", format: "float", example: 85.5),
                        new OA\Property(property: "Address", type: "string", example: "Casablanca, Maroc"),
                        new OA\Property(property: "HasProductsInCategories", type: "string", nullable: true, example: "Électronique, Accessoires"),
                        new OA\Property(property: "TotalProducts", type: "integer", example: 48),
                        new OA\Property(property: "TotalVentes", type: "integer", example: 1200),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Profil vendeur introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Profil vendeur introuvable."),
            ]
        )
    )]
    #[OA\Response(
        response: 500,
        description: "Erreur interne du serveur",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string"),
            ]
        )
    )]
    public function publicProfile(int $vendorProfileID): JsonResponse
    {
        if ($vendorProfileID <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de profil vendeur invalide.',
            ], 404);
        }

        try {
            $result = $this->vendorService->getPublicProfile($vendorProfileID);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        if (!$result) {
            return response()->json([
                'success' => false,
                'message' => 'Profil vendeur introuvable.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $result->toArray(),
        ], 200);
    }
}