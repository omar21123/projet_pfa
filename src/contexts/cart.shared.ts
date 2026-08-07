import { createContext, useContext } from "react";

export interface CartItem {
  id: string;
  adId: string;
  title: string;
  price: number;
  image: string;
  seller: string;
  quantity: number;
  addedAt: Date;
  compositionId?: number | null;
}

export interface CartContextType {
  cartItems: CartItem[];
  totalPrice: number;
  totalItems: number;
  loading: boolean;
  addToCart: (payload: any) => Promise<void>;
  removeFromCart: (payload: any) => Promise<void>;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
  checkout: () => void;
  fetchCart: () => Promise<void>;
}

export const CartContext = createContext<CartContextType | undefined>(undefined);

export const useCart = () => {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error("useCart doit être utilisé à l'intérieur d'un CartProvider.");
  }
  return context;
};
