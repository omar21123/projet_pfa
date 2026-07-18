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

const extractRefreshData = (payload: any): string | null => {
  return payload?.access_token || payload?.data?.access_token || null;
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
    if (accessToken) {
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
      requestUrl.includes("/api/auth/web/vendor/register");

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
  } catch {
    setAuthAccessToken(null);
    return null;
  }
};

export default axiosInstance;