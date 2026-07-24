import { STORAGE_KEYS } from "@/config/constants";
import { getAuthAccessToken } from "@/api/axiosInstance";
import { apiClient } from "@/api/client";

export interface FavoriteCountResponse {
  data: number;
  message: string;
}

const getBearerToken = () => getAuthAccessToken() ?? localStorage.getItem(STORAGE_KEYS.TOKEN);

const getAuthHeaders = () => {
  const token = getBearerToken();
  return token ? { Authorization: `Bearer ${token}` } : undefined;
};

export const favoritesApi = {
  add: async (annonceId: string | number): Promise<FavoriteCountResponse> => {
    const { data } = await apiClient.post<FavoriteCountResponse>(`/add/${annonceId}`, undefined, {
      headers: getAuthHeaders(),
    });

    return data;
  },
  remove: async (annonceId: string | number): Promise<FavoriteCountResponse> => {
    const { data } = await apiClient.delete<FavoriteCountResponse>(`/remove/${annonceId}`, {
      headers: getAuthHeaders(),
    });

    return data;
  },
};
