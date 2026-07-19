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

const extractRefreshData = (payload: unknown): RefreshTokenData | null => {
  const direct = payload as { accessToken?: string; data?: RefreshTokenData };
  if (direct?.accessToken) {
    return { accessToken: direct.accessToken };
  }

  if (direct?.data?.accessToken) {
    return { accessToken: direct.data.accessToken };
  }

  const nested = payload as { data?: { accessToken?: string; data?: RefreshTokenData } };
  if (nested?.data?.accessToken) {
    return { accessToken: nested.data.accessToken };
  }

  if (nested?.data?.data?.accessToken) {
    return { accessToken: nested.data.data.accessToken };
  }

  return null;
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

    // Skip refresh for auth endpoints
    const isAuthEndpoint =
      requestUrl.includes("/api/auth/login") ||
      requestUrl.includes("/api/auth/refresh") ||
      requestUrl.includes("/api/auth/logout") ||
      requestUrl.includes("/api/auth/register");

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
      const response = await axios.post(
        `${API_BASE_URL}/api/Auth/refresh`,
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
      localStorage.setItem(AUTH_TOKEN_KEY, innerData.accessToken);

      // Process queued requests
      processRefreshQueue(null, innerData.accessToken);

      // Retry original request
      originalRequest.headers = originalRequest.headers ?? {};
      originalRequest.headers.Authorization = `Bearer ${innerData.accessToken}`;

      return axiosInstance(originalRequest);
    } catch (refreshError) {
      processRefreshQueue(refreshError, null);
      setAuthAccessToken(null);
      localStorage.removeItem(AUTH_TOKEN_KEY);
      window.dispatchEvent(new Event("unauthorized"));
      return Promise.reject(refreshError);
    } finally {
      isRefreshing = false;
    }
  },
);

export default axiosInstance;
