import { apiClient } from "@/api/client";
import type { ApiResponse, UserProfile, ApiMessageResponse } from "@/types";

const unwrapApiResponse = <T>(payload: ApiResponse<T>, fallbackMessage: string): T => {
  if (!payload.success) {
    throw new Error(payload.message || (payload.errors && payload.errors[0]) || fallbackMessage);
  }

  return payload.data;
};

export const usersApi = {
  getCurrentUserProfile: async (): Promise<UserProfile> => {
    const response = await apiClient.get<ApiResponse<UserProfile>>("/api/Users/me");
    return unwrapApiResponse(response.data, "Impossible de recuperer le profil courant.");
  },

  getAll: async (): Promise<UserProfile[]> => {
    const response = await apiClient.get<ApiResponse<UserProfile[]>>("/api/Users");
    return unwrapApiResponse(response.data, "Impossible de recuperer la liste des utilisateurs.");
  },

  getById: async (id: number): Promise<UserProfile> => {
    const response = await apiClient.get<ApiResponse<UserProfile>>(`/api/Users/${id}`);
    return unwrapApiResponse(response.data, "Impossible de recuperer le profil utilisateur.");
  },

  update: async (id: number, payloadData: Partial<UserProfile>): Promise<UserProfile> => {
    const response = await apiClient.put<ApiResponse<UserProfile>>(`/api/Users/${id}`, payloadData);
    return unwrapApiResponse(response.data, "Impossible de mettre a jour l'utilisateur.");
  },

  postActivity: async (data: unknown): Promise<ApiMessageResponse> => {
    const response = await apiClient.post<ApiResponse<null>>("/api/Users/activity", data);
    const payload = response.data;
    unwrapApiResponse(payload, "Erreur lors de l'enregistrement de l'activité utilisateur.");

    return { message: payload.message };
  },
};
