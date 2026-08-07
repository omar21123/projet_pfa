import { apiClient } from "@/api/client";
import type {
  AddFavoriteRequest,
  FavoriteCreated,
  FavoritesResponse,
} from "@/features/favorites/types";
import type { ApiMessageResult, ApiSuccess } from "@/types/wishlist";

export const getFavorites = async (): Promise<FavoritesResponse> => {
  const { data } = await apiClient.get<FavoritesResponse>("/api/favorites");
  return data;
};

export const addFavorite = async (
  payload: AddFavoriteRequest,
): Promise<ApiSuccess<FavoriteCreated>> => {
  const { data } = await apiClient.post<ApiSuccess<FavoriteCreated>>(
    "/api/favorites",
    payload,
  );
  return data;
};

export const removeFavorite = async (productId: number): Promise<ApiMessageResult> => {
  const { data } = await apiClient.delete<ApiMessageResult>(`/api/favorites/${productId}`);
  return data;
};

export const favoritesApi = {
  list: getFavorites,
  add: addFavorite,
  remove: removeFavorite,
};
