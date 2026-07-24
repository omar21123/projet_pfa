declare module "@/api/axiosInstance" {
  import type { AxiosInstance } from "axios";

  export function setAuthAccessToken(token: string | null): void;
  export function getAuthAccessToken(): string | null;

  const axiosInstance: AxiosInstance;
  export default axiosInstance;
}
