import { env } from "@/config/env";

export const resolveImageUrl = (path?: string) => {
  if (!path) return "/placeholder-ad.png";
  if (/^https?:\/\//i.test(path)) return path;
  const baseUrl = env.apiUrl || "https://localhost:7111";
  try {
    return new URL(path, baseUrl).toString();
  } catch {
    return path;
  }
};

export default resolveImageUrl;
