import { apiClient } from "../../api/client";
import type {
  AddCartItemRequest,
  CartMutationResponse,
  CartResponse,
  RemoveCartItemRequest,
} from "@/types/cart";

export const getCart = async (): Promise<CartResponse> => {
  const { data } = await apiClient.get<CartResponse>("/api/cart");
  return data;
};

export const addCartItem = async (payload: AddCartItemRequest): Promise<CartMutationResponse> => {
  const { data } = await apiClient.post<CartMutationResponse>("/api/cart/items", payload);
  return data;
};

export const removeCartItem = async (
  payload: RemoveCartItemRequest,
): Promise<CartMutationResponse> => {
  const { data } = await apiClient.delete<CartMutationResponse>("/api/cart/items", {
    data: payload,
  });
  return data;
};

export const cartApi = {
  get: getCart,
  addItem: addCartItem,
  removeItem: removeCartItem,
};
