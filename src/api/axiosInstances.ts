// src/api/axiosInstances.ts
import axios, { AxiosError, InternalAxiosRequestConfig, AxiosResponse } from "axios";
import { env } from "@/config/env";
import { RefreshTokenResponse } from "../types/users.types";

const API_BASE_URL = env.apiUrl;

interface QueuedRequest {
  resolve: (token: string) => void;
  reject: (error: unknown) => void;
}

let accessToken: string | null = null;
let isRefreshing = false;
let refreshQueue: QueuedRequest[] = [];

const extractRefreshData = (payload: unknown): string | null => {
  if (typeof payload !== "object" || payload === null) return null;

  const root = payload as Record<string, unknown>;
  const nested =
    typeof root.data === "object" && root.data !== null
      ? (root.data as Record<string, unknown>)
      : undefined;
  const token =
    root.access_token ||
    root.accessToken ||
    root.session_token ||
    root.sessionToken ||
    nested?.access_token ||
    nested?.accessToken ||
    nested?.session_token ||
    nested?.sessionToken;

  return typeof token === "string" && token ? token : null;
};

const processRefreshQueue = (error: unknown = null, token: string | null = null): void => {
  refreshQueue.forEach(({ resolve, reject }) => {
    if (error) {
      reject(error);
    } else if (token) {
      resolve(token);
    }
  });
  refreshQueue = [];
};

export const setAuthAccessToken = (token: string | null): void => {
  accessToken = token;
};

export const getAuthAccessToken = (): string | null => accessToken;

const axiosInstance = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,
  headers: {
    "Content-Type": "application/json",
  },
});

axiosInstance.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // 🟢 FIX : ne pas écraser un Authorization déjà injecté manuellement
    // (ex: Bearer <google_id_token> pour l'onboarding)
    const existingAuth =
      config.headers?.Authorization || config.headers?.authorization;

    if (accessToken && !existingAuth) {
      config.headers = config.headers ?? {};
      config.headers.Authorization = `Bearer ${accessToken}`;
    }
    return config;
  },
  (error: AxiosError) => Promise.reject(error),
);

axiosInstance.interceptors.response.use(
  (response: AxiosResponse) => response,
  async (error: AxiosError) => {
    const originalRequest = error?.config as InternalAxiosRequestConfig & { _retry?: boolean };
    const status = error?.response?.status;
    const requestUrl = (originalRequest?.url ?? "").toLowerCase();

    const isAuthEndpoint =
      requestUrl.includes("/api/auth/web/login") ||
      requestUrl.includes("/api/auth/web/refresh") ||
      requestUrl.includes("/api/auth/web/logout") ||
      requestUrl.includes("/api/auth/web/customer/register") ||
      requestUrl.includes("/api/auth/web/vendor/register") ||
      requestUrl.includes("/api/auth/google/complete-profile"); // 🟢 exclure aussi l'onboarding

    if (status !== 401 || !originalRequest || originalRequest._retry || isAuthEndpoint) {
      return Promise.reject(error);
    }

    if (isRefreshing) {
      return new Promise<string>((resolve, reject) => {
        refreshQueue.push({ resolve, reject });
      })
        .then((token: string) => {
          originalRequest.headers = originalRequest.headers ?? {};
          originalRequest.headers.Authorization = `Bearer ${token}`;
          return axiosInstance(originalRequest);
        })
        .catch((queueError) => Promise.reject(queueError));
    }

    originalRequest._retry = true;
    isRefreshing = true;

    try {
      const response = await axios.post<RefreshTokenResponse>(
        `${API_BASE_URL}/api/auth/web/refresh`,
        {},
        {
          withCredentials: true,
          headers: { "Content-Type": "application/json" },
        },
      );

      const newAccessToken = extractRefreshData(response.data);

      if (!newAccessToken) {
        throw new Error("Format de réponse refresh token invalide");
      }

      setAuthAccessToken(newAccessToken);
      processRefreshQueue(null, newAccessToken);

      originalRequest.headers = originalRequest.headers ?? {};
      originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;

      return axiosInstance(originalRequest);
    } catch (refreshError: unknown) {
      const refreshStatus = axios.isAxiosError(refreshError)
        ? refreshError.response?.status
        : undefined;

      // 🟢 FIX : ne déconnecter que si le serveur rejette explicitement le refresh token (401)
      if (refreshStatus === 401) {
        processRefreshQueue(refreshError, null);
        setAuthAccessToken(null);
        window.dispatchEvent(new Event("unauthorized"));
      } else {
        processRefreshQueue(refreshError, null);
      }
      return Promise.reject(refreshError);
    } finally {
      isRefreshing = false;
    }
  },
);

export const silentRefresh = async (): Promise<string | null> => {
  try {
    const response = await axios.post<RefreshTokenResponse>(
      `${API_BASE_URL}/api/auth/web/refresh`,
      {},
      {
        withCredentials: true,
        headers: { "Content-Type": "application/json" },
      },
    );
    const newAccessToken = extractRefreshData(response.data);
    if (newAccessToken) {
      setAuthAccessToken(newAccessToken);
      return newAccessToken;
    }
    return null;
  } catch (error: unknown) {
    // 🟢 FIX : ne pas effacer le token sur une 404 ou erreur réseau
    if (axios.isAxiosError(error) && error.response?.status === 401) {
      setAuthAccessToken(null);
    }
    return null;
  }
};

export default axiosInstance;
