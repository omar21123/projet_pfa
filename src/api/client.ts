/**
 * API Client - Re-export from axiosInstance
 *
 * This file provides a consistent import path for the API client.
 * All API calls should use this client which includes:
 * - Automatic token injection via interceptors
 * - Automatic token refresh on 401 responses
 * - Proper TypeScript typing
 */
export { default as apiClient } from "./axiosInstances";
export { setAuthAccessToken, getAuthAccessToken } from "./axiosInstances";
