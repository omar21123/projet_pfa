import axios, { AxiosError, InternalAxiosRequestConfig, AxiosResponse } from "axios";
import { env } from "@/config/env";

const AUTH_TOKEN_KEY = "authToken";
const API_BASE_URL = env.apiUrl;

interface RefreshTokenData {
  accessToken: string;
}

interface QueuedRequest {
  resolve: (token: string) => void;
  reject: (error: unknown) => void;
}

let accessToken: string | null = localStorage.getItem(AUTH_TOKEN_KEY);
let isRefreshing = false;
let refreshQueue: QueuedRequest[] = [];

/**
 * Supporte à la fois 'access_token' (Laravel) et 'accessToken' (JS/TS)
 */
const extractRefreshData = (payload: any): RefreshTokenData | null => {
  if (!payload) return null;

  const token =
    payload.access_token ||
    payload.accessToken ||
    payload.data?.access_token ||
    payload.data?.accessToken ||
    payload.data?.data?.access_token ||
    payload.data?.data?.accessToken;

  return token ? { accessToken: token } : null;
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

/**
 * 🟢 FIX 1 : Synchronise la variable locale ET localStorage
 */
export const setAuthAccessToken = (token: string | null): void => {
  accessToken = token;
  if (token) {
    localStorage.setItem(AUTH_TOKEN_KEY, token);
  } else {
    localStorage.removeItem(AUTH_TOKEN_KEY);
  }
};

export const getAuthAccessToken = (): string | null => {
  return accessToken || localStorage.getItem(AUTH_TOKEN_KEY);
};

const axiosInstance = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,
  headers: {
    "Content-Type": "application/json",
  },
});

axiosInstance.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // S'assurer de toujours récupérer le token le plus récent
    const currentToken = getAuthAccessToken();
    if (currentToken) {
      config.headers = config.headers ?? {};
      config.headers.Authorization = `Bearer ${currentToken}`;
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

    // 🟢 FIX 2 : Ne pas tenter de refresh si l'erreur provient de la finalisation Google
    const isAuthEndpoint =
      requestUrl.includes("/auth/login") ||
      requestUrl.includes("/auth/refresh") ||
      requestUrl.includes("/auth/logout") ||
      requestUrl.includes("/auth/register") ||
      requestUrl.includes("/google/complete-profile");

    if (status !== 401 || !originalRequest || originalRequest._retry || isAuthEndpoint) {
      return Promise.reject(error);
    }

    // If already refreshing, queue this request
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
      // 🟢 FIX 3 : URL alignée avec vos routes Laravel (/api/auth/web/refresh)
      const response = await axios.post(
        `${API_BASE_URL}/api/auth/web/refresh`,
        {},
        {
          withCredentials: true,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );

      const innerData = extractRefreshData(response.data);

      if (!innerData?.accessToken) {
        throw new Error("Invalid refresh token response format");
      }

      setAuthAccessToken(innerData.accessToken);

      // Process queued requests
      processRefreshQueue(null, innerData.accessToken);

      // Retry original request
      originalRequest.headers = originalRequest.headers ?? {};
      originalRequest.headers.Authorization = `Bearer ${innerData.accessToken}`;

      return axiosInstance(originalRequest);
    } catch (refreshError) {
      processRefreshQueue(refreshError, null);
      setAuthAccessToken(null);
      window.dispatchEvent(new Event("unauthorized"));
      return Promise.reject(refreshError);
    } finally {
      isRefreshing = false;
    }
  },
);

export default axiosInstance;