import { createContext, type ReactNode, useCallback, useState } from "react";

export interface CartItem {
  id: string;
  adId: string;
  title: string;
  price: number;
  image: string;
  seller: string;
  quantity: number;
  addedAt: Date;
}

export interface CartContextType {
  cartItems: CartItem[];
  totalPrice: number;
  totalItems: number;
  addToCart: (
    adId: string,
    title: string,
    price: number,
    image: string,
    seller: string,
    quantity?: number,
  ) => void;
  removeFromCart: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
  checkout: () => void;
}

export const CartContext = createContext<CartContextType | undefined>(undefined);

interface CartProviderProps {
  children: ReactNode;
}

export const CartProvider = ({ children }: CartProviderProps) => {
  const [cartItems, setCartItems] = useState<CartItem[]>([]);

  const addToCart = useCallback(
    (
      adId: string,
      title: string,
      price: number,
      image: string,
      seller: string,
      quantity: number = 1,
    ) => {
      setCartItems((prev) => {
        const existingItem = prev.find((item) => item.adId === adId);

        if (existingItem) {
          return prev.map((item) =>
            item.adId === adId ? { ...item, quantity: item.quantity + quantity } : item,
          );
        }

        const newItem: CartItem = {
          id: Date.now().toString(),
          adId,
          title,
          price,
          image,
          seller,
          quantity,
          addedAt: new Date(),
        };

        return [...prev, newItem];
      });
    },
    [],
  );

  const removeFromCart = useCallback((id: string) => {
    setCartItems((prev) => prev.filter((item) => item.id !== id));
  }, []);

  const updateQuantity = useCallback(
    (id: string, quantity: number) => {
      if (quantity <= 0) {
        removeFromCart(id);
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
    console.log("Checkout with items:", cartItems);
    clearCart();
  }, [cartItems, clearCart]);

  const totalPrice = cartItems.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const totalItems = cartItems.reduce((sum, item) => sum + item.quantity, 0);

  const value: CartContextType = {
    cartItems,
    totalPrice,
    totalItems,
    addToCart,
    removeFromCart,
    updateQuantity,
    clearCart,
    checkout,
  };

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
};
