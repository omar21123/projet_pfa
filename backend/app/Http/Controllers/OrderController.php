<?php

namespace App\Http\Controllers;

use App\DTOs\Order\CreateOrderForProductDto;
use App\DTOs\Order\CreateOrderFromCartDto;
use App\Http\Requests\Order\CreateOrderForProductRequest;
use App\Http\Requests\Order\CreateOrderFromCartRequest;
use App\Services\Interface\DeliveryServiceInterface;
use App\Services\Interface\OrderServiceInterface;
use App\Services\Interface\UserServiceInterface;
use App\Services\Interface\VendorServiceInterface;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;

#[OA\Tag(
    name: "Orders",
    description: "Gestion des commandes"
)]
class OrderController extends Controller
{
    public function __construct(
        protected OrderServiceInterface $orderService,
        private UserServiceInterface $userService,
        protected VendorServiceInterface $vendorService,
        protected DeliveryServiceInterface $delivery_service

    ) {}

    #[OA\Post(
        path: "/api/orders/product",
        tags: ["Orders"],
        summary: "Créer une commande pour un seul produit",
        description: "Crée une commande directement pour un produit unique (flux \"acheter maintenant\"). Résout le prix via la combinaison (variante) si fournie, applique une promotion éligible si fournie, vérifie le stock, puis calcule les totaux de la commande (Subtotal, ShippingFee = 10%, Total). UserPublicID est déduit du token JWT.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["AddressID", "PaymentMethodID", "ProductID", "Quantity"],
            properties: [
                new OA\Property(
                    property: "AddressID",
                    type: "integer",
                    description: "Identifiant de l'adresse de l'utilisateur, utilisée comme adresse de facturation et de livraison.",
                    example: 12
                ),
                new OA\Property(
                    property: "PaymentMethodID",
                    type: "integer",
                    description: "Identifiant du moyen de paiement.",
                    example: 2
                ),
                new OA\Property(
                    property: "ProductID",
                    type: "integer",
                    description: "Identifiant du produit à commander.",
                    example: 452
                ),
                new OA\Property(
                    property: "Quantity",
                    type: "integer",
                    minimum: 1,
                    description: "Quantité commandée.",
                    example: 2
                ),
                new OA\Property(
                    property: "CombinationID",
                    type: "integer",
                    nullable: true,
                    description: "Identifiant de la variante (combinaison) du produit, si applicable.",
                    example: 12
                ),
                new OA\Property(
                    property: "PromotionID",
                    type: "integer",
                    nullable: true,
                    description: "Identifiant de la promotion à appliquer, si applicable.",
                    example: 7
                ),
                new OA\Property(
                    property: "Notes",
                    type: "string",
                    nullable: true,
                    maxLength: 255,
                    description: "Notes libres associées à la commande.",
                    example: "Livrer avant 18h si possible."
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Commande créée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Commande créée avec succès."),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "order_id", type: "integer", example: 981),
                        new OA\Property(property: "order_number", type: "string", example: "ORD-20260815-042"),
                        new OA\Property(property: "user_id", type: "integer", example: 34),
                        new OA\Property(property: "billing_address_id", type: "integer", example: 12),
                        new OA\Property(property: "shipping_address_id", type: "integer", example: 12),
                        new OA\Property(property: "order_status_id", type: "integer", example: 2),
                        new OA\Property(property: "payment_method_id", type: "integer", example: 2),
                        new OA\Property(property: "subtotal", type: "number", format: "float", example: 298.00),
                        new OA\Property(property: "shipping_fee", type: "number", format: "float", example: 29.80),
                        new OA\Property(property: "discount", type: "number", format: "float", example: 0),
                        new OA\Property(property: "tax", type: "number", format: "float", example: 0),
                        new OA\Property(property: "total", type: "number", format: "float", example: 327.80),
                        new OA\Property(property: "currency", type: "string", example: "MAD"),
                        new OA\Property(property: "notes", type: "string", nullable: true),
                        new OA\Property(property: "created_at", type: "string", format: "date-time"),
                    ]
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur, produit, variante ou adresse introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Utilisateur introuvable."),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Règle métier violée (stock insuffisant, promotion invalide/expirée, limite d'utilisation atteinte, etc.)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Stock insuffisant pour la quantité demandée."),
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
    public function createForProduct(CreateOrderForProductRequest $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');

        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable.',
            ], 404);
        }

        $validated = $request->validated();

        $dto = CreateOrderForProductDto::fromArray([
            'UserPublicID'    => $publicId,
            'AddressID'       => $validated['AddressID'],
            'PaymentMethodID' => $validated['PaymentMethodID'],
            'ProductID'       => $validated['ProductID'],
            'Quantity'        => $validated['Quantity'],
            'CombinationID'   => $validated['CombinationID'] ?? null,
            'PromotionID'     => $validated['PromotionID'] ?? null,
            'Notes'           => $validated['Notes'] ?? null,
        ]);

        try {
            $order = $this->orderService->createOrderForProduct($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Commande créée avec succès.',
            'data' => $order->toArray(),
        ], 201);
    }
    // app/Http/Controllers/OrderController.php — add to the class

    #[OA\Post(
        path: "/api/orders/cart",
        tags: ["Orders"],
        summary: "Créer une commande à partir du panier",
        description: "Crée une commande à partir de l'intégralité du panier de l'utilisateur connecté. Chaque article du panier est ajouté à la commande via SP_CreateOrderItem (résolution du prix, stock, promotion), puis les totaux de la commande sont recalculés. Le panier est vidé une fois la commande créée. UserPublicID est déduit du token JWT.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["AddressID", "PaymentMethodID"],
            properties: [
                new OA\Property(property: "AddressID", type: "integer", example: 12),
                new OA\Property(property: "PaymentMethodID", type: "integer", example: 2),
                new OA\Property(property: "Notes", type: "string", nullable: true, maxLength: 255, example: "Livrer avant 18h si possible."),
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Commande créée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Commande créée avec succès."),
                new OA\Property(property: "data", type: "object"),
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Utilisateur, produit, variante ou adresse introuvable",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Utilisateur introuvable."),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Panier vide ou règle métier violée (stock insuffisant, promotion invalide, etc.)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Votre panier est vide."),
            ]
        )
    )]
    public function createFromCart(CreateOrderFromCartRequest $request): JsonResponse
    {
        $publicId = $request->attributes->get('user_id');

        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable.',
            ], 404);
        }

        $validated = $request->validated();

        $dto = CreateOrderFromCartDto::fromArray([
            'UserPublicID'    => $publicId,
            'AddressID'       => $validated['AddressID'],
            'PaymentMethodID' => $validated['PaymentMethodID'],
            'Notes'           => $validated['Notes'] ?? null,
        ]);

        try {
            $order = $this->orderService->createOrderFromCart($dto);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Commande créée avec succès.',
            'data' => $order->toArray(),
        ], 201);
    }
    #[OA\Patch(
        path: "/api/orders/{order}/ship",
        tags: ["Deliveries"],
        summary: "Marquer sa partie de commande comme expédiée",
        description: "Le vendeur connecté confirme que ses articles de la commande sont prêts à être expédiés. Nécessite que sa livraison associée soit au statut 'picked_up' ou supérieur. La commande passe au statut 'Shipped' uniquement lorsque tous les vendeurs concernés ont confirmé.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "order",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 88
    )]
    #[OA\Response(
        response: 200,
        description: "Statut mis à jour",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Commande marquée comme expédiée avec succès."),
                new OA\Property(property: "order_fully_shipped", type: "boolean", example: true),
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Livraison non récupérée, vendeur sans articles dans la commande, ou commande non confirmée",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Votre livraison doit être récupérée par le livreur avant de marquer la commande comme expédiée."),
            ]
        )
    )]
    public function shipOrder(int $order): JsonResponse
    {
        if ($order <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de commande invalide.',
            ], 404);
        }

        $publicId = request()->attributes->get('user_id');
        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable.',
            ], 404);
        }

        $vendorProfile = $this->vendorService->getVendorProfileByUserId($userInfo->userId);

        if (!$vendorProfile) {
            return response()->json([
                'success' => false,
                'message' => 'Profil vendeur introuvable pour cet utilisateur.',
            ], 404);
        }

        try {
            $result = $this->delivery_service->markOrderAsShipped($order, $vendorProfile->vendorProfileId);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 422);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => $result->message,
            'order_fully_shipped' => $result->orderFullyShipped,
        ], 200);
    }
    #[OA\Get(
        path: "/api/orders/{order}/details",
        tags: ["Orders"],
        summary: "Détails complets d'une commande (client)",
        description: "Retourne toutes les informations d'une commande du client connecté : articles (avec produit, image, vendeur et email), livraisons par vendeur avec adresses géolocalisées, livreur assigné, et historique complet des statuts de livraison.",
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "order",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", minimum: 1),
        example: 88
    )]
    #[OA\Response(
        response: 200,
        description: "Commande récupérée avec succès",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "data", type: "object"),
            ]
        )
    )]
    #[OA\Response(response: 404, description: "Commande introuvable ou n'appartenant pas à cet utilisateur")]
    public function customerOrderDetails(int $order): JsonResponse
    {
        if ($order <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant de commande invalide.',
            ], 404);
        }

        $publicId = request()->attributes->get('user_id');
        $userInfo = $this->userService->getUserStandardInformationByPublicID($publicId);

        if (!$userInfo) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable.',
            ], 404);
        }

        try {
            $result = $this->orderService->getCustomerOrderDetails($order, $userInfo->userId);
        } catch (\App\Exceptions\BusinessValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $e->getCode() ?: 404);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'data' => $result->toArray(),
        ], 200);
    }
}
