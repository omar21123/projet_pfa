import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/api/client"; // Réutilise ton instance configurée

export interface CategoryNode {
  CategoryID?: number;
  category_id?: number; // Convention API Laravel (snake_case)
  id?: number; // Compatibilité ascendante
  Name?: string;
  name?: string; // Compatibilité ascendante[cite: 3]
  nom?: string; // Compatibilité ascendante[cite: 3]
  Slug?: string;
  slug?: string;
  ParentCategoryID?: number | null;
  parent_category_id?: number | null; // Convention API Laravel (snake_case)
  IconURL?: string | null;
  icon_url?: string | null;
  IsActive?: boolean | number;
  is_active?: boolean | number;
  children_count?: number;
  DisplayOrder?: number; // Tri du Navbar[cite: 3]
  display_order?: number; // Convention API Laravel (snake_case)
  Depth?: number; // Structure du Navbar[cite: 3]
  children?: CategoryNode[];
}

interface LaravelApiResponse<T> {
  success: boolean;
  message?: string;
  data: T;
}

// 1. 🛡️ Récupération des catégories racines (Admin) - ANTI-CRASH POUR VISITEURS
const fetchRootCategories = async (): Promise<CategoryNode[]> => {
  try {
    const response = await apiClient.get<LaravelApiResponse<CategoryNode[]>>("/api/categories", {
      timeout: 5000,
    });
    return response.data?.success && Array.isArray(response.data?.data) ? response.data.data : [];
  } catch (error: any) {
    // 💡 Si le serveur renvoie 401 (visiteur anonyme), on renvoie un tableau vide proprement
    if (error?.response?.status === 401) {
      console.warn(
        "[Categories API] Route admin '/api/categories' protégée (401). Retour d'un tableau vide pour le visiteur.",
      );
      return [];
    }
    // Si c'est une autre erreur (ex: 500 ou réseau), on la propage
    throw error;
  }
};

// 2. 🛡️ Récupération des catégories du Navbar (arbre déjà construit côté backend)
const fetchNavbarCategories = async (): Promise<CategoryNode[]> => {
  try {
    const response = await apiClient.get<LaravelApiResponse<CategoryNode[]>>(
      "/api/categories/navbar",
      {
        timeout: 5000,
      },
    );

    const raw = response.data;
    const items =
      Array.isArray(raw?.data)
        ? raw.data
        : Array.isArray(raw)
          ? raw
          : [];

    // Tri par DisplayOrder, appliqué récursivement (le backend renvoie déjà les enfants imbriqués
    // dans `children`, donc on ne fait plus de reconstruction manuelle du type parent/enfant)
    const sortFn = (a: CategoryNode, b: CategoryNode) =>
      (a.display_order ?? a.DisplayOrder ?? 0) - (b.display_order ?? b.DisplayOrder ?? 0);

    const sortTree = (nodes: CategoryNode[]): CategoryNode[] =>
      [...nodes].sort(sortFn).map((node) => ({
        ...node,
        children: node.children && node.children.length > 0 ? sortTree(node.children) : node.children,
      }));

    return sortTree(items);
  } catch (error: any) {
    console.error(
      "[Categories API] Impossible de récupérer l'arbre des catégories du Navbar",
      error,
    );
    return [];
  }
};

// Centralisation des clés de requêtes React Query
export const categoriesQueryKeys = {
  all: ["categories"] as const,
  roots: () => [...categoriesQueryKeys.all, "roots"] as const,
  navbar: () => [...categoriesQueryKeys.all, "navbar"] as const, // Clé spécifique pour le Navbar
};

// Hook existant pour l'administration (liste de catégories racines)
export const useCategories = () => {
  return useQuery({
    queryKey: categoriesQueryKeys.roots(),
    queryFn: fetchRootCategories,
    staleTime: 1000 * 60 * 10, // Cache de 10 minutes
    retry: false, // 💡 Ne pas s'acharner à requêter en boucle en cas de 401
  });
};

// Nouveau hook pour récupérer et structurer les données du Navbar
export const useNavbarCategories = () => {
  return useQuery({
    queryKey: categoriesQueryKeys.navbar(),
    queryFn: fetchNavbarCategories,
    staleTime: 1000 * 60 * 15, // Cache de 15 minutes (le menu de navigation change rarement)
    retry: false,
  });
};