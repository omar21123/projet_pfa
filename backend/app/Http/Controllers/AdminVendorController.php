<?php

namespace App\Http\Controllers;

use App\DTOs\Admin\VendorListFilterDto;
use App\Services\Interface\AdminVendorServiceInterface;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;
use App\DTOs\Admin\VerifyIdentityDto;
use App\Services\UserService;
use Illuminate\Validation\Rule;
use App\DTOs\Admin\ApproveVendorDto;
use App\Exceptions\VendorApprovalException;
use App\DTOs\Admin\RejectVendorDto;
use App\DTOs\Admin\ResetVendorToPendingDto;


#[OA\Tag(
    name: "Admin - Vendors",
    description: "Gestion des vendeurs par l'administrateur"
)]
class AdminVendorController extends Controller
{
    public function __construct(private AdminVendorServiceInterface $adminVendorService, private UserService $userService) {}

    #[OA\Get(
        path: "/api/admin/vendors",
        tags: ["Admin - Vendors"],
        summary: "Liste des vendeurs (paginée)",
        description: "Retourne la liste des vendeurs avec statistiques agrégées (produits, commandes, revenu) et filtres de recherche/statut.",
        parameters: [
            new OA\Parameter(name: "search", in: "query", required: false, schema: new OA\Schema(type: "string")),
            new OA\Parameter(name: "verification_status", in: "query", required: false, schema: new OA\Schema(type: "integer")),
            new OA\Parameter(name: "is_suspended", in: "query", required: false, schema: new OA\Schema(type: "integer", enum: [0, 1])),
            new OA\Parameter(name: "page", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 1)),
            new OA\Parameter(name: "page_size", in: "query", required: false, schema: new OA\Schema(type: "integer", default: 20)),
        ]
    )]
    #[OA\Response(
        response: 200,
        description: "Liste récupérée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "status", type: "integer", example: 200),
                new OA\Property(property: "message", type: "string", example: "Vendeurs récupérés avec succès."),
                new OA\Property(property: "data", type: "object"),
            ]
        )
    )]
    public function AdminGetAll(Request $request)
    {
        $filter = VendorListFilterDto::fromArray($request->query());

        $result = $this->adminVendorService->getAll($filter);

        return response()->json([
            'success' => true,
            'status' => 200,
            'data' => $result,
            'message' => 'Vendeurs récupérés avec succès.',
        ], 200);
    }



    #[OA\Post(
        path: "/api/admin/vendors/{vendorProfileId}/verify-identity",
        tags: ["Admin - Vendors"],
        summary: "Vérifier l'identité d'un vendeur",
        description: "Marque l'identité d'un vendeur comme vérifiée et enregistre l'administrateur ayant effectué la vérification.",
        parameters: [
            new OA\Parameter(name: "vendorProfileId", in: "path", required: true, schema: new OA\Schema(type: "integer")),
        ],
        requestBody: new OA\RequestBody(
            required: false,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: "verification_notes", type: "string", maxLength: 500, nullable: true),
                ]
            )
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Identité vérifiée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "status", type: "integer", example: 200),
                new OA\Property(property: "message", type: "string", example: "Identité du vendeur vérifiée avec succès."),
                new OA\Property(property: "data", type: "object"),
            ]
        )
    )]
    public function AdminVerifyIdentity(Request $request, int $vendorProfileId)
    {
        $request->validate([
            'verification_notes' => ['nullable', 'string', 'max:500'],
        ]);
        $publicID = $request->attributes->get('user_id');
        $currentUser = $this->userService->getUserStandardInformationByPublicID($publicID);
        $dto = VerifyIdentityDto::fromRequest(
            vendorProfileId: $vendorProfileId,
            verifiedBy: $currentUser->userId,
            verificationNotes: $request->input('verification_notes'),
        );

        $result = $this->adminVendorService->verifyIdentity($dto);

        return response()->json([
            'success' => true,
            'status' => 200,
            'data' => $result,
            'message' => 'Identité du vendeur vérifiée avec succès.',
        ], 200);
    }

    #[OA\Post(
        path: "/api/admin/vendors/{vendorProfileId}/approve",
        tags: ["Admin - Vendors"],
        summary: "Approuver un vendeur",
        description: "Approuve un vendeur uniquement si l'identité, l'entreprise et la banque sont déjà vérifiées.",
        parameters: [
            new OA\Parameter(name: "vendorProfileId", in: "path", required: true, schema: new OA\Schema(type: "integer")),
        ],
        requestBody: new OA\RequestBody(
            required: false,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: "verification_notes", type: "string", maxLength: 500, nullable: true),
                ]
            )
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Vendeur approuvé avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "status", type: "integer", example: 200),
                new OA\Property(property: "message", type: "string", example: "Vendeur approuvé avec succès."),
                new OA\Property(property: "data", type: "object"),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Vendeur non éligible à l'approbation (vérifications manquantes)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "status", type: "integer", example: 422),
                new OA\Property(property: "message", type: "string", example: "Cannot approve vendor: identity, business, and bank must all be verified first."),
            ]
        )
    )]
    public function AdminApproveVendor(Request $request, int $vendorProfileId)
    {
        $request->validate([
            'verification_notes' => ['nullable', 'string', 'max:500'],
        ]);
        $publicID = $request->attributes->get('user_id');
        $currentUser = $this->userService->getUserStandardInformationByPublicID($publicID);

        $dto = ApproveVendorDto::fromRequest(
            vendorProfileId: $vendorProfileId,
            verifiedBy: $currentUser->userId,
            verificationNotes: $request->input('verification_notes'),
        );

        try {
            $result = $this->adminVendorService->approveVendor($dto);
        } catch (VendorApprovalException $e) {
            return response()->json([
                'success' => false,
                'status' => 422,
                'message' => $e->getMessage(),
            ], 422);
        }

        return response()->json([
            'success' => true,
            'status' => 200,
            'data' => $result,
            'message' => 'Vendeur approuvé avec succès.',
        ], 200);
    }
    #[OA\Post(
        path: "/api/admin/vendors/{vendorProfileId}/reject",
        tags: ["Admin - Vendors"],
        summary: "Rejeter un vendeur",
        description: "Marque un vendeur comme rejeté et enregistre le motif du rejet.",
        parameters: [
            new OA\Parameter(name: "vendorProfileId", in: "path", required: true, schema: new OA\Schema(type: "integer")),
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["rejection_notes"],
                properties: [
                    new OA\Property(property: "rejection_notes", type: "string", maxLength: 500),
                ]
            )
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Vendeur rejeté avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "status", type: "integer", example: 200),
                new OA\Property(property: "message", type: "string", example: "Vendeur rejeté avec succès."),
                new OA\Property(property: "data", type: "object"),
            ]
        )
    )]
    public function AdminRejectVendor(Request $request, int $vendorProfileId)
    {
        $request->validate([
            'rejection_notes' => ['required', 'string', 'max:500'],
        ]);
          $publicID = $request->attributes->get('user_id');
        $currentUser = $this->userService->getUserStandardInformationByPublicID($publicID);
        $dto = RejectVendorDto::fromRequest(
            vendorProfileId: $vendorProfileId,
            verifiedBy: $currentUser->userId,
            rejectionNotes: $request->input('rejection_notes'),
        );

        $result = $this->adminVendorService->rejectVendor($dto);

        return response()->json([
            'success' => true,
            'status' => 200,
            'data' => $result,
            'message' => 'Vendeur rejeté avec succès.',
        ], 200);
    }

#[OA\Post(
    path: "/api/admin/vendors/{vendorProfileId}/reset-to-pending",
    tags: ["Admin - Vendors"],
    summary: "Réinitialiser un vendeur au statut en attente",
    description: "Remet le statut de vérification d'un vendeur à 'Pending', efface l'approbation et le rejet.",
    parameters: [
        new OA\Parameter(name: "vendorProfileId", in: "path", required: true, schema: new OA\Schema(type: "integer")),
    ],
    requestBody: new OA\RequestBody(
        required: false,
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "notes", type: "string", maxLength: 500, nullable: true),
            ]
        )
    )
)]
#[OA\Response(
    response: 200,
    description: "Vendeur réinitialisé avec succès",
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: "success", type: "boolean", example: true),
            new OA\Property(property: "status", type: "integer", example: 200),
            new OA\Property(property: "message", type: "string", example: "Vendeur remis en attente avec succès."),
            new OA\Property(property: "data", type: "object"),
        ]
    )
)]
public function AdminResetVendorToPending(Request $request, int $vendorProfileId)
{
    $request->validate([
        'notes' => ['nullable', 'string', 'max:500'],
    ]);
    $publicID = $request->attributes->get('user_id');
        $currentUser = $this->userService->getUserStandardInformationByPublicID($publicID);
    $dto = ResetVendorToPendingDto::fromRequest(
        vendorProfileId: $vendorProfileId,
        verifiedBy: $currentUser->userId,
        notes: $request->input('notes'),
    );

    $result = $this->adminVendorService->resetVendorToPending($dto);

    return response()->json([
        'success' => true,
        'status' => 200,
        'data' => $result,
        'message' => 'Vendeur remis en attente avec succès.',
    ], 200);
}
}
