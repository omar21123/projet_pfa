import defaultAds from "./defaultAds.json";
import { Ad } from "@/types/ad.types";

/**
 * Récupère les annonces par défaut depuis le fichier JSON
 */
export function getDefaultAds(): Ad[] {
  return defaultAds as Ad[];
}

/**
 * Récupère une annonce par ID
 */
export function getAdById(id: string): Ad | undefined {
  return defaultAds.find((ad: Ad) => ad.id === id);
}

/**
 * Récupère les annonces par catégorie
 */
export function getAdsByCategory(category: string): Ad[] {
  return defaultAds.filter((ad: Ad) => ad.category === category);
}

/**
 * Récupère les catégories disponibles
 */
export function getCategories(): string[] {
  const categories = new Set((defaultAds as Ad[]).map((ad) => ad.category));
  return Array.from(categories).sort();
}

// Export direct des annonces par défaut
export { defaultAds };
