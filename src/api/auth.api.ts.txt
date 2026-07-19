// src/api/auth.api.ts
import { apiClient } from "./client";
import {
  ApiResponse,
  LoginRequest,
  RegisterRequest,
  UserProfile,
  VerifyEmailRequest,
  AuthResponse,
  ApiMessageResponse,
} from "../types/user.types";

const unwrapApiResponse = <T>(payload: ApiResponse<T>, fallbackMessage: string): T => {
  if (!payload.success) {
    throw new Error(payload.message || payload.errors[0] || fallbackMessage);
  }

  return payload.data;
};

export const authApi = {
  login: async (data: LoginRequest): Promise<AuthResponse> => {
    const response = await apiClient.post<ApiResponse<{ accessToken: string }>>(
      "/api/Auth/login",
      data,
    );
    const payload = response.data;
    const tokenData = unwrapApiResponse(payload, "Echec de l'authentification.");

    localStorage.setItem("authEmail", data.email);

    return {
      token: tokenData.accessToken,
      message: payload.message,
    };
  },

  register: async (data: RegisterRequest): Promise<ApiMessageResponse> => {
    const response = await apiClient.post<ApiResponse<string>>("/api/Auth/register", data);
    const payload = response.data;

    unwrapApiResponse(payload, "Erreur lors de l'inscription.");

    return {
      message: payload.message,
    };
  },

  verifyEmail: async (data: VerifyEmailRequest): Promise<ApiMessageResponse> => {
    const response = await apiClient.post<ApiResponse<null>>("/api/Auth/verify-email", null, {
      params: data,
    });
    const payload = response.data;

    unwrapApiResponse(payload, "Erreur lors de la verification de l'email.");

    return {
      message: payload.message,
    };
  },

  getCurrentUserProfile: async (): Promise<UserProfile> => {
    const response = await apiClient.get<ApiResponse<UserProfile>>("/api/Auth/me");
    return unwrapApiResponse(response.data, "Impossible de recuperer le profil utilisateur.");
  },

  getUserProfile: async (id: number): Promise<UserProfile> => {
    const response = await apiClient.get<ApiResponse<UserProfile>>(`/api/Auth/${id}`);
    return unwrapApiResponse(response.data, "Impossible de recuperer le profil utilisateur.");
  },
};
