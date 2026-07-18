interface Env {
  apiUrl: string;
}

const normalizeUrl = (value: string): string => value.replace(/\/$/, "");

const resolveApiUrl = (): string =>
  import.meta.env.VITE_API_BASE_URL || import.meta.env.VITE_API_URL || "http://localhost";

export const env: Env = {
  apiUrl: normalizeUrl(resolveApiUrl()),
};
