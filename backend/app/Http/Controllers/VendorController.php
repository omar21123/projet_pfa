<?php

namespace App\Http\Controllers;

use App\DTOs\Vendor\RequestVendorWithdrawDto;
use App\Http\Requests\Vendor\PaginationRequest;
use App\Http\Requests\Vendor\RequestVendorWithdrawRequest;
use App\Services\Interface\VendorServiceInterface;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;
use Symfony\Component\HttpFoundation\Request;

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
    #[OA\Get(
    path: "/api/vendor/bank-account",
    tags: ["Vendors"],
    summary: "Voir mon compte bancaire (vendeur)",
    description: "Retourne le solde total, disponible, en attente (bloqué par des holds), et le nombre/montant des holds actifs.",
    security: [["bearerAuth" => []]]
)]
#[OA\Response(
    response: 200,
    description: "Compte récupéré avec succès",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "success", type: "boolean", example: true),
            new OA\Property(property: "bank_account_id", type: "integer", example: 12),
            new OA\Property(property: "vendor_profile_id", type: "integer", example: 5),
            new OA\Property(property: "current_balance", type: "number", format: "float", example: 4200.00),
            new OA\Property(property: "withdrawable_balance", type: "number", format: "float", example: 1800.00),
            new OA\Property(property: "pending_balance", type: "number", format: "float", example: 2400.00),
            new OA\Property(property: "currency_code", type: "string", example: "MAD"),
            new OA\Property(property: "is_locked", type: "boolean", example: false),
            new OA\Property(property: "total_held", type: "number", format: "float", example: 2400.00),
            new OA\Property(property: "active_holds_count", type: "integer", example: 3),
        ]
    )
)]
#[OA\Response(response: 404, description: "Compte bancaire introuvable")]
public function myBankAccount(Request $request): JsonResponse
{
    $publicId = $request->attributes->get('user_id');
    $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

    if (!$userInfo) {
        return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
    }

    $vendorProfile = $this->vendorService->getVendorProfileByUserId($userInfo->userId);

    if (!$vendorProfile) {
        return response()->json(['success' => false, 'message' => 'Profil vendeur introuvable pour cet utilisateur.'], 404);
    }

    $account = $this->vendorService->getBankAccountByVendorProfileId($vendorProfile->vendorProfileId);

    if (!$account) {
        return response()->json(['success' => false, 'message' => 'Compte bancaire introuvable.'], 404);
    }

    return response()->json(array_merge(['success' => true], $account->toArray()), 200);
}

#[OA\Get(
    path: "/api/vendor/withdrawals",
    tags: ["Vendors"],
    summary: "Historique de mes retraits (vendeur)",
    security: [["bearerAuth" => []]]
)]
#[OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1))]
#[OA\Parameter(name: "per_page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20))]
#[OA\Response(response: 200, description: "Historique récupéré avec succès")]
public function myWithdrawHistory(PaginationRequest $request): JsonResponse
{
    $publicId = $request->attributes->get('user_id');
    $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

    if (!$userInfo) {
        return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
    }

    $vendorProfile = $this->vendorService->getVendorProfileByUserId($userInfo->userId);

    if (!$vendorProfile) {
        return response()->json(['success' => false, 'message' => 'Profil vendeur introuvable pour cet utilisateur.'], 404);
    }

    $validated = $request->validated();
    $page = (int) ($validated['page'] ?? 1);
    $perPage = (int) ($validated['per_page'] ?? 20);

    $result = $this->vendorService->getVendorWithdrawHistory($vendorProfile->vendorProfileId, $page, $perPage);

    return response()->json($result->toArray(), 200);
}

#[OA\Post(
    path: "/api/vendor/withdraw",
    tags: ["Vendors"],
    summary: "Demander un retrait (vendeur)",
    security: [["bearerAuth" => []]]
)]
#[OA\RequestBody(
    required: true,
    content: new OA\JsonContent(
        required: ["Amount", "PaymentMethodID"],
        properties: [
            new OA\Property(property: "Amount", type: "number", format: "float", example: 1500.00),
            new OA\Property(property: "PaymentMethodID", type: "integer", example: 2),
        ]
    )
)]
#[OA\Response(response: 200, description: "Demande de retrait envoyée avec succès")]
#[OA\Response(response: 422, description: "Solde insuffisant ou compte bloqué")]
public function requestWithdraw(RequestVendorWithdrawRequest $request): JsonResponse
{
    $publicId = $request->attributes->get('user_id');
    $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

    if (!$userInfo) {
        return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
    }

    $vendorProfile = $this->vendorService->getVendorProfileByUserId($userInfo->userId);

    if (!$vendorProfile) {
        return response()->json(['success' => false, 'message' => 'Profil vendeur introuvable pour cet utilisateur.'], 404);
    }

    $validated = $request->validated();
    $dto = new RequestVendorWithdrawDto(
        vendorProfileId: $vendorProfile->vendorProfileId,
        amount: (float) $validated['Amount'],
        paymentMethodId: (int) $validated['PaymentMethodID'],
    );

    try {
        $withdrawId = $this->vendorService->requestVendorWithdraw($dto);
    } catch (\App\Exceptions\BusinessValidationException $e) {
        return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 422);
    } catch (\Throwable $e) {
        return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
    }

    return response()->json([
        'success'     => true,
        'message'     => 'Demande de retrait envoyée avec succès.',
        'withdraw_id' => $withdrawId,
    ], 200);
}
}