// src/api/auth.api.ts
import axiosInstance, {
  setAuthAccessToken,
  getAuthAccessToken,
} from "./axiosInstances";
import type { AxiosRequestConfig } from "axios";
import {
  LoginRequest,
  RegisterRequestClient,
  LaravelAuthResponse,
  ApiMessageResponse,
  User,
  CompleteGoogleProfilePayload,
} from "../types/users.types";

const AUTH_EMAIL_KEY = "authEmail";
const GOOGLE_SESSION_TOKEN_KEY = "google_session_token";

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

const extractAccessToken = (payload: unknown): string | null => {
  if (!isRecord(payload)) return null;

  const nested = isRecord(payload.data) ? payload.data : undefined;
  const token =
    payload.access_token ??
    payload.accessToken ??
    payload.session_token ??
    payload.sessionToken ??
    payload.token ??
    nested?.access_token ??
    nested?.accessToken ??
    nested?.session_token ??
    nested?.sessionToken ??
    nested?.token;

  return typeof token === "string" && token ? token : null;
};

const normalizeAuthResponse = (payload: unknown): LaravelAuthResponse => {
  const root = isRecord(payload) ? payload : {};
  const nested = isRecord(root.data) ? root.data : {};
  const token = extractAccessToken(payload);

  return {
    ...nested,
    ...root,
    ...(token ? { access_token: token } : {}),
  } as LaravelAuthResponse;
};

export type GoogleLoginPayload =
  | string
  | {
      id_token: string;
      role?: "CUSTOMER" | "VENDOR";
      first_name?: string;
      last_name?: string;
      store_name?: string;
      description?: string;
      phone_number?: string;
      birth_date?: string;
      gender?: number;
    };

export const authApi = {
  login: async (data: LoginRequest): Promise<LaravelAuthResponse> => {
    const response = await axiosInstance.post<LaravelAuthResponse>(
      "/api/auth/web/login",
      data
    );
    const payload = normalizeAuthResponse(response.data);
    if (!payload.access_token) {
      throw new Error("Réponse de connexion invalide : token manquant.");
    }
    setAuthAccessToken(payload.access_token);
    localStorage.setItem(AUTH_EMAIL_KEY, data.email);
    return payload;
  },

  registerClient: async (data: RegisterRequestClient): Promise<ApiMessageResponse> => {
    const response = await axiosInstance.post<ApiMessageResponse>(
      "/api/auth/web/customer/register",
      data
    );
    return response.data;
  },

  registerVendor: async (formData: FormData): Promise<ApiMessageResponse> => {
    const response = await axiosInstance.post<ApiMessageResponse>(
      "/api/auth/web/vendor/register",
      formData,
      {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      }
    );
    return response.data;
  },

  loginWithGoogle: async (payload: GoogleLoginPayload): Promise<LaravelAuthResponse> => {
    sessionStorage.removeItem(GOOGLE_SESSION_TOKEN_KEY);
    const body = typeof payload === "string" ? { id_token: payload } : payload;
    const response = await axiosInstance.post<LaravelAuthResponse>(
      "/api/auth/web/google",
      body
    );
    const responseData = normalizeAuthResponse(response.data);
    if (responseData.access_token) {
      setAuthAccessToken(responseData.access_token);
      sessionStorage.setItem(GOOGLE_SESSION_TOKEN_KEY, responseData.access_token);
    }
    return responseData;
  },

  completeGoogleProfile: async (
    data: CompleteGoogleProfilePayload
  ): Promise<LaravelAuthResponse> => {
    const sessionToken =
      getAuthAccessToken() || sessionStorage.getItem(GOOGLE_SESSION_TOKEN_KEY);

    if (!sessionToken) {
      throw new Error("Jeton de session Google manquant ou expiré.");
    }

    const config: AxiosRequestConfig = {};
    config.headers = { Authorization: `Bearer ${sessionToken}` };

    const response = await axiosInstance.post<LaravelAuthResponse>(
      "/api/auth/google/complete-profile",
      data,
      config
    );
    const payload = normalizeAuthResponse(response.data);
    if (payload.access_token) {
      setAuthAccessToken(payload.access_token);
      sessionStorage.removeItem(GOOGLE_SESSION_TOKEN_KEY);
    }
    return payload;
  },

  logout: async (): Promise<ApiMessageResponse> => {
    try {
      const response = await axiosInstance.post<ApiMessageResponse>("/api/auth/web/logout");
      return response.data;
    } finally {
      setAuthAccessToken(null);
      localStorage.removeItem(AUTH_EMAIL_KEY);
      sessionStorage.removeItem(GOOGLE_SESSION_TOKEN_KEY);
    }
  },

  getCurrentUserProfile: async (): Promise<User> => {
    const response = await axiosInstance.get<User>("/api/auth/me");
    return response.data;
  },
};
