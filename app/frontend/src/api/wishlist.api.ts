import { apiClient } from "./client";
import type {
  AddWishlistItemRequest,
  ApiMessageResult,
  ApiSuccess,
  CreateWishlistRequest,
  Wishlist,
  WishlistItemCreated,
} from "@/types/wishlist";

export const getWishlists = async (): Promise<ApiSuccess<Wishlist[]>> => {
  const { data } = await apiClient.get<ApiSuccess<Wishlist[]>>("/api/wishlists");
  return data;
};

export const createWishlist = async (
  payload: CreateWishlistRequest = {},
): Promise<ApiSuccess<Wishlist>> => {
  const { data } = await apiClient.post<ApiSuccess<Wishlist>>("/api/wishlists", payload);
  return data;
};

export const addWishlistItem = async (
  wishListId: number,
  payload: AddWishlistItemRequest,
): Promise<ApiSuccess<WishlistItemCreated>> => {
  const { data } = await apiClient.post<ApiSuccess<WishlistItemCreated>>(
    `/api/wishlists/${wishListId}/items`,
    payload,
  );
  return data;
};

export const removeWishlistItem = async (
  wishListItemId: number,
): Promise<ApiMessageResult> => {
  const { data } = await apiClient.delete<ApiMessageResult>(
    `/api/wishlists/items/${wishListItemId}`,
  );
  return data;
};

export const deleteWishlist = async (wishListId: number): Promise<ApiMessageResult> => {
  const { data } = await apiClient.delete<ApiMessageResult>(`/api/wishlists/${wishListId}`);
  return data;
};

export const wishlistApi = {
  list: getWishlists,
  create: createWishlist,
  addItem: addWishlistItem,
  removeItem: removeWishlistItem,
  delete: deleteWishlist,
};
