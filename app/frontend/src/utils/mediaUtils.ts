// src/utils/mediaUtils.ts
import { env } from "@/config/env";

const BACKEND_BASE_URL = env.apiUrl;
export const getMediaUrl = (path?: string | null): string => {
  if (!path || typeof path !== "string" || path.trim() === "") {
    return "https://via.placeholder.com/800x600?text=Image+indisponible";
  }

  // 1. Nettoyer les antislashs d'échappement JSON (transforme \/ en /)
  let cleanPath = path.replace(/\\/g, "").trim();

  // 2. Remplacer l'adresse 127.0.0.1:8000 renvoyée par le backend par votre domaine valide (localhost)
  if (cleanPath.includes("127.0.0.1:8000")) {
    cleanPath = cleanPath.replace(/http:\/\/127\.0\.0\.1:8000/g, BACKEND_BASE_URL);
  }

  // 3. Si c'est déjà une URL absolue complète (ex: http://localhost/storage/...)
  if (
    cleanPath.startsWith("http://") ||
    cleanPath.startsWith("https://") ||
    cleanPath.startsWith("data:")
  ) {
    return cleanPath;
  }

  // 4. Traitement des chemins relatifs (ex: /storage/avatars/image.jpg)
  cleanPath = cleanPath.replace(/^app\/public\//, "").replace(/^public\//, "");

  if (!cleanPath.startsWith("/")) {
    cleanPath = `/${cleanPath}`;
  }

  return `${BACKEND_BASE_URL}${cleanPath}`;
};
