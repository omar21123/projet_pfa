import { type ReactNode, useCallback, useEffect, useState } from "react";
import { cartApi } from "@/features/cart/cart.api";
import type { AddCartItemRequest, RemoveCartItemRequest } from "@/types/cart";
import { CartContext, type CartItem } from "@/contexts/cart.shared";
import { useAuth } from "@/contexts";
import { getMediaUrl } from "@/utils/mediaUtils";

interface CartProviderProps {
  children: ReactNode;
}

export const CartProvider = ({ children }: CartProviderProps) => {
  const { isAuthenticated } = useAuth();
  const [cartItems, setCartItems] = useState<CartItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  const fetchCart = useCallback(async () => {
    // Si le visiteur n'est pas connecté, on ne déclenche pas la requête API pour éviter le 401
    if (!isAuthenticated) {
      setCartItems([]);
      setLoading(false);
      return;
    }

    setLoading(true);
    try {
      const response = await cartApi.get();
      const rawItems = response?.data ?? (Array.isArray(response) ? response : []);

      const formattedItems: CartItem[] = (rawItems as unknown[]).map(
        (item: unknown, index: number) => {
          const it = item as Record<string, unknown>;
          const productId = it.ProductID ?? it.productId ?? it.id ?? index;
          const compositionId =
            it.CompositionID ??
            it.CompositionId ??
            it.CombinationID ??
            it.CombinationId ??
            it.combinationId ??
            it.compositionId ??
            null;
          const title = (it.ProductName ?? it.productName ?? it.title ?? "Produit") as string;
          const price = Number(it.UnitPrice ?? it.unitPrice ?? it.price ?? 0) || 0;
          const rawImage = it.ImagePath ?? it.imagePath ?? it.image ?? "/placeholder.png";
          const image = getMediaUrl(
            typeof rawImage === "string" ? rawImage : String(rawImage ?? ""),
          );
          const seller = (it.BrandName ?? it.brandName ?? it.seller ?? "Vendeur") as string;
          const quantity = Number(it.Quantity ?? it.quantity ?? 1) || 1;

          return {
            id: String(productId),
            adId: String(productId),
            title,
            price,
            image,
            seller,
            quantity,
            addedAt: new Date(),
            compositionId,
          } as CartItem;
        },
      );

      setCartItems(formattedItems);
    } catch (error: unknown) {
      // N'afficher la stack que si ce n'est pas une erreur d'auth (401)
      if (typeof error === "object" && error !== null) {
        const err = error as Record<string, unknown>;
        const status = (err["response"] as Record<string, unknown> | undefined)?.["status"] as
          | number
          | undefined;
        if (status !== 401) console.error("Erreur panier:", error);
      } else {
        console.error("Erreur panier:", error);
      }
      setCartItems([]);
    } finally {
      setLoading(false);
    }
  }, [isAuthenticated]);

  useEffect(() => {
    fetchCart();
  }, [fetchCart]);

  const addToCart = useCallback(
    async (payload: AddCartItemRequest) => {
      try {
        await cartApi.addItem(payload);
        await fetchCart();
      } catch (error) {
        console.error("Erreur d'ajout au panier:", error);
        throw error;
      }
    },
    [fetchCart],
  );

  const removeFromCart = useCallback(
    async (payload: RemoveCartItemRequest) => {
      try {
        await cartApi.removeItem(payload);
        await fetchCart();
      } catch (error) {
        console.error("Erreur de suppression:", error);
        throw error;
      }
    },
    [fetchCart],
  );

  const updateQuantity = useCallback(
    (id: string, quantity: number) => {
      if (quantity <= 0) {
        removeFromCart({ productID: Number(id) });
        return;
      }
      setCartItems((prev) => prev.map((item) => (item.id === id ? { ...item, quantity } : item)));
    },
    [removeFromCart],
  );

  const clearCart = useCallback(() => {
    setCartItems([]);
  }, []);

  const checkout = useCallback(() => {
    console.log("Checkout :", cartItems);
    clearCart();
  }, [cartItems, clearCart]);

  const totalPrice = cartItems.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const totalItems = cartItems.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <CartContext.Provider
      value={{
        cartItems,
        totalPrice,
        totalItems,
        loading,
        addToCart,
        removeFromCart,
        updateQuantity,
        clearCart,
        checkout,
        fetchCart,
      }}
    >
      {children}
    </CartContext.Provider>
  );
};
