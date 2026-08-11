<?php
// App\Http\Controllers\AddressController
namespace App\Http\Controllers;

use App\Http\Requests\Address\AddressRequest;
use App\Http\Requests\Address\UserIDRequest;
use App\Services\Interface\AddressServiceInterface;
use App\Services\Interface\UserServiceInterface;
use App\Services\Interface\VendorServiceInterface;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Addresses",
    description: "Gestion des adresses utilisateur"
)]
class AddressController extends Controller
{
    public function __construct(
        protected AddressServiceInterface $addressService,
        protected UserServiceInterface    $userService,
        protected VendorServiceInterface  $vendorService,
    ) {}

    private function resolveUserID(Request $request): ?int
    {
        $publicId = $request->attributes->get('user_id');
        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);
        return $userInfo?->userId;
    }

    #[OA\Get(
        path: "/api/addresses",
        tags: ["Addresses"],
        summary: "Lister les adresses de l'utilisateur connecté",
        description: "Retourne toutes les adresses enregistrées pour l'utilisateur authentifié, triées par adresse de livraison par défaut en premier.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Response(
        response: 200,
        description: "Adresses récupérées avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "data",    type: "array", items: new OA\Items(type: "object")),
            ]
        )
    )]
    #[OA\Response(response: 404, description: "Utilisateur introuvable")]
    public function index(Request $request): JsonResponse
    {
        $userID = $this->resolveUserID($request);

        if (!$userID) {
            return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
        }

        try {
            $addresses = $this->addressService->getAllByUserID($userID);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json([
            'success' => true,
            'data'    => array_map(fn($a) => $a->toArray(), $addresses),
        ], 200);
    }

    #[OA\Get(
        path: "/api/addresses/{address}",
        tags: ["Addresses"],
        summary: "Détails d'une adresse",
        description: "Retourne une adresse spécifique appartenant à l'utilisateur authentifié.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "address", in: "path", required: true, schema: new OA\Schema(type: "integer"), example: 3)]
    #[OA\Response(response: 200, description: "Adresse récupérée avec succès")]
    #[OA\Response(response: 404, description: "Adresse ou utilisateur introuvable")]
    public function show(Request $request, int $address): JsonResponse
    {
        if ($address <= 0) {
            return response()->json(['success' => false, 'message' => 'Identifiant d\'adresse invalide.'], 404);
        }

        $userID = $this->resolveUserID($request);

        if (!$userID) {
            return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
        }

        try {
            $result = $this->addressService->getByID($address, $userID);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        if (!$result) {
            return response()->json(['success' => false, 'message' => 'Adresse introuvable.'], 404);
        }

        return response()->json(['success' => true, 'data' => $result->toArray()], 200);
    }

    #[OA\Post(
        path: "/api/addresses",
        tags: ["Addresses"],
        summary: "Ajouter une adresse",
        description: "Crée une nouvelle adresse pour l'utilisateur authentifié. Si IsDefaultShipping=true, toute adresse de livraison par défaut précédente est automatiquement désactivée.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["full_name", "country", "city", "address_line1"],
            properties: [
                new OA\Property(property: "full_name",           type: "string",  example: "Mohammed Alami"),
                new OA\Property(property: "phone",               type: "string",  nullable: true, example: "+212600000000"),
                new OA\Property(property: "country",             type: "string",  example: "Maroc"),
                new OA\Property(property: "region",              type: "string",  nullable: true, example: "Casablanca-Settat"),
                new OA\Property(property: "city",                type: "string",  example: "Casablanca"),
                new OA\Property(property: "postal_code",         type: "string",  nullable: true, example: "20000"),
                new OA\Property(property: "address_line1",       type: "string",  example: "12 Rue Hassan II"),
                new OA\Property(property: "address_line2",       type: "string",  nullable: true, example: "Appt 4"),
                new OA\Property(property: "landmark",            type: "string",  nullable: true, example: "Près de la pharmacie"),
                new OA\Property(property: "latitude",            type: "number",  nullable: true, example: 33.5731104),
                new OA\Property(property: "longitude",           type: "number",  nullable: true, example: -7.5898434),
                new OA\Property(property: "is_default_shipping", type: "boolean", nullable: true, example: true),
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Adresse créée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success",    type: "boolean", example: true),
                new OA\Property(property: "message",    type: "string",  example: "Adresse ajoutée avec succès."),
                new OA\Property(property: "address_id", type: "integer", example: 12),
            ]
        )
    )]
    #[OA\Response(response: 404, description: "Utilisateur introuvable")]
    #[OA\Response(response: 422, description: "Règle métier violée")]
    public function store(AddressRequest $request): JsonResponse
    {
        $userID = $this->resolveUserID($request);

        if (!$userID) {
            return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
        }

        try {
            $addressID = $this->addressService->create($userID, $request->validated());
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 422);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json([
            'success'    => true,
            'message'    => 'Adresse ajoutée avec succès.',
            'address_id' => $addressID,
        ], 201);
    }

    #[OA\Put(
        path: "/api/addresses/{address}",
        tags: ["Addresses"],
        summary: "Mettre à jour une adresse",
        description: "Met à jour une adresse existante appartenant à l'utilisateur authentifié.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "address", in: "path", required: true, schema: new OA\Schema(type: "integer"), example: 3)]
    #[OA\Response(response: 200, description: "Adresse mise à jour avec succès")]
    #[OA\Response(response: 404, description: "Adresse ou utilisateur introuvable")]
    #[OA\Response(response: 422, description: "Règle métier violée")]
    public function update(AddressRequest $request, int $address): JsonResponse
    {
        if ($address <= 0) {
            return response()->json(['success' => false, 'message' => 'Identifiant d\'adresse invalide.'], 404);
        }

        $userID = $this->resolveUserID($request);

        if (!$userID) {
            return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
        }

        try {
            $this->addressService->update($address, $userID, $request->validated());
        } catch (\App\Exceptions\BusinessValidationException $e) {
            $code = str_contains($e->getMessage(), 'introuvable') ? 404 : ($e->getCode() ?: 422);
            return response()->json(['success' => false, 'message' => $e->getMessage()], $code);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json(['success' => true, 'message' => 'Adresse mise à jour avec succès.'], 200);
    }

    #[OA\Delete(
        path: "/api/addresses/{address}",
        tags: ["Addresses"],
        summary: "Supprimer une adresse",
        description: "Supprime définitivement une adresse appartenant à l'utilisateur authentifié.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "address", in: "path", required: true, schema: new OA\Schema(type: "integer"), example: 3)]
    #[OA\Response(response: 200, description: "Adresse supprimée avec succès")]
    #[OA\Response(response: 404, description: "Adresse ou utilisateur introuvable")]
    public function destroy(Request $request, int $address): JsonResponse
    {
        if ($address <= 0) {
            return response()->json(['success' => false, 'message' => 'Identifiant d\'adresse invalide.'], 404);
        }

        $userID = $this->resolveUserID($request);

        if (!$userID) {
            return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
        }

        try {
            $this->addressService->delete($address, $userID);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            $code = str_contains($e->getMessage(), 'introuvable') ? 404 : ($e->getCode() ?: 422);
            return response()->json(['success' => false, 'message' => $e->getMessage()], $code);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json(['success' => true, 'message' => 'Adresse supprimée avec succès.'], 200);
    }

    #[OA\Patch(
        path: "/api/addresses/{address}/default-shipping",
        tags: ["Addresses"],
        summary: "Définir comme adresse de livraison par défaut",
        description: "Définit une adresse comme adresse de livraison par défaut pour l'utilisateur. Désactive automatiquement toute adresse de livraison par défaut précédente.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "address", in: "path", required: true, schema: new OA\Schema(type: "integer"), example: 3)]
    #[OA\Response(response: 200, description: "Adresse de livraison par défaut mise à jour")]
    #[OA\Response(response: 404, description: "Adresse ou utilisateur introuvable")]
    public function setDefaultShipping(Request $request, int $address): JsonResponse
    {
        if ($address <= 0) {
            return response()->json(['success' => false, 'message' => 'Identifiant d\'adresse invalide.'], 404);
        }

        $userID = $this->resolveUserID($request);

        if (!$userID) {
            return response()->json(['success' => false, 'message' => 'Utilisateur introuvable.'], 404);
        }

        try {
            $this->addressService->setDefaultShipping($address, $userID);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            $code = str_contains($e->getMessage(), 'introuvable') ? 404 : ($e->getCode() ?: 422);
            return response()->json(['success' => false, 'message' => $e->getMessage()], $code);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        return response()->json(['success' => true, 'message' => 'Adresse de livraison par défaut mise à jour.'], 200);
    }
    // getDefaultShippingAddress()
    #[OA\Get(path: "/api/addresses/shipping/default", tags: ["Addresses"], summary: "Récupérer l'adresse de livraison par défaut")]
    #[OA\Parameter(name: "user_id", in: "query", required: true, schema: new OA\Schema(type: "integer"), example: 1)]
    #[OA\Response(
        response: 200,
        description: "Adresse de livraison récupérée avec succès",
        content: new OA\JsonContent(properties: [
            new OA\Property(property: "success",      type: "boolean", example: true),
            new OA\Property(property: "data",         type: "object",  properties: [
                new OA\Property(property: "FullName",     type: "string",  example: "Mohammed Alami"),
                new OA\Property(property: "Phone",        type: "string",  nullable: true),
                new OA\Property(property: "Country",      type: "string",  example: "Maroc"),
                new OA\Property(property: "Region",       type: "string",  nullable: true),
                new OA\Property(property: "City",         type: "string",  example: "Casablanca"),
                new OA\Property(property: "PostalCode",   type: "string",  nullable: true),
                new OA\Property(property: "AddressLine1", type: "string",  example: "12 Rue Hassan II"),
                new OA\Property(property: "AddressLine2", type: "string",  nullable: true),
                new OA\Property(property: "Landmark",     type: "string",  nullable: true),
                new OA\Property(property: "Latitude",     type: "number",  nullable: true),
                new OA\Property(property: "Longitude",    type: "number",  nullable: true),
            ]),
        ])
    )]
    #[OA\Response(response: 404, description: "Utilisateur introuvable ou aucune adresse enregistrée")]
    public function getDefaultShippingAddress(UserIDRequest $request): JsonResponse
    {
        $userID = (int) $request->validated()['user_id'];

        try {
            $result = $this->addressService->getDefaultShippingAddress($userID);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], $e->getCode() ?: 404);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        if (!$result) {
            return response()->json(['success' => false, 'message' => 'Aucune adresse de livraison trouvée.'], 404);
        }

        return response()->json(['success' => true, 'data' => $result->toArray()], 200);
    }

    #[OA\Get(
        path: "/api/addresses/orders/{order}/shipping-address",
        tags: ["Addresses"],
        summary: "Récupérer l'adresse de livraison d'une commande",
        description: "Accessible aux vendeurs ayant un article dans la commande et aux administrateurs.",
        operationId: "getOrderShippingAddress",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(name: "order", in: "path", required: true, schema: new OA\Schema(type: "integer"), example: 101)]
    #[OA\Response(
        response: 200,
        description: "Adresse de livraison récupérée avec succès",
        content: new OA\JsonContent(properties: [
            new OA\Property(property: "success", type: "boolean", example: true),
            new OA\Property(property: "data", type: "object", properties: [
                new OA\Property(property: "FullName", type: "string", example: "Mohammed Alami"),
                new OA\Property(property: "Phone", type: "string", nullable: true, example: "+212600000000"),
                new OA\Property(property: "Country", type: "string", example: "Maroc"),
                new OA\Property(property: "Region", type: "string", nullable: true, example: "Casablanca-Settat"),
                new OA\Property(property: "City", type: "string", example: "Casablanca"),
                new OA\Property(property: "PostalCode", type: "string", nullable: true, example: "20000"),
                new OA\Property(property: "AddressLine1", type: "string", example: "12 Rue Hassan II"),
                new OA\Property(property: "AddressLine2", type: "string", nullable: true, example: "Appt 4"),
                new OA\Property(property: "Landmark", type: "string", nullable: true, example: "Près de la pharmacie"),
                new OA\Property(property: "Latitude", type: "number", format: "float", nullable: true, example: 33.5731104),
                new OA\Property(property: "Longitude", type: "number", format: "float", nullable: true, example: -7.5898434),
            ]),
        ])
    )]
    #[OA\Response(response: 401, description: "Non authentifié")]
    #[OA\Response(response: 403, description: "Accès non autorisé")]
    #[OA\Response(response: 404, description: "Commande, profil vendeur ou adresse introuvable")]
    public function getOrderShippingAddress(Request $request, int $order): JsonResponse
    {
        if ($order <= 0) {
            return response()->json(['success' => false, 'message' => 'Identifiant de commande invalide.'], 404);
        }

        $role = strtoupper((string) $request->attributes->get('user_role'));
        $vendorProfileID = null;

        if ($role === 'VENDOR') {
            $userID = $this->resolveUserID($request);
            $vendorProfile = $userID ? $this->vendorService->getVendorProfileByUserId($userID) : null;

            if (!$vendorProfile) {
                return response()->json(['success' => false, 'message' => 'Profil vendeur introuvable.'], 404);
            }

            $vendorProfileID = $vendorProfile->vendorProfileId;
        }

        try {
            $result = $this->addressService->getOrderShippingAddress($order, $vendorProfileID);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            $status = str_contains($e->getMessage(), 'Non autorisé') ? 403 : 404;
            return response()->json(['success' => false, 'message' => $e->getMessage()], $status);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        if (!$result) {
            return response()->json(['success' => false, 'message' => 'Aucune adresse de livraison associée à cette commande.'], 404);
        }

        return response()->json(['success' => true, 'data' => $result->toArray()], 200);
    }
}
