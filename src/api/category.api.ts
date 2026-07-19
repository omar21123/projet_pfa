import axiosInstance from "./axiosInstances"; // Réutilise ton instance configurée
import { 
  PaginatedCategoryResponse, 
  SingleCategoryResponse, 
  ActionCategoryResponse, 
  CategoryFilters, 
  NavbarCategoryResponse
} from "../types/category.types";

export const categoryApi = {
  /**
   * 1. Récupérer les catégories racines avec filtres et pagination
   */
  getRootCategories: async (filters: CategoryFilters = {}): Promise<PaginatedCategoryResponse> => {
    const response = await axiosInstance.get<PaginatedCategoryResponse>("/api/categories", {
      params: filters
    });
    return response.data;
  },

  /**
   * 2. Récupérer les sous-catégories directes d'un parent
   */
  getChildren: async (id: number, filters: CategoryFilters = {}): Promise<PaginatedCategoryResponse> => {
    const response = await axiosInstance.get<PaginatedCategoryResponse>(`/api/categories/${id}/children`, {
      params: filters
    });
    return response.data;
  },

  /**
   * 3. Créer une nouvelle catégorie (Gère l'envoi d'image binaire via FormData)
   */
  createCategory: async (formData: FormData): Promise<SingleCategoryResponse> => {
    const response = await axiosInstance.post<SingleCategoryResponse>("/api/categories/create", formData, {
      headers: {
        "Content-Type": "multipart/form-data"
      }
    });
    return response.data;
  },

  /**
   * 4. Activer une catégorie
   */
  activate: async (id: number): Promise<ActionCategoryResponse> => {
    const response = await axiosInstance.put<ActionCategoryResponse>(`/api/categories/${id}/activate`);
    return response.data;
  },

  /**
   * 5. Désactiver une catégorie et tout son arbre (subtree)
   */
  deactivateSubtree: async (id: number): Promise<ActionCategoryResponse> => {
    const response = await axiosInstance.put<ActionCategoryResponse>(`/api/categories/${id}/deactivate-subtree`);
    return response.data;
  },
  /**
   * 6. Récupérer les catégories actives pour le Navbar
   */
   getNavbarCategories: async (): Promise<NavbarCategoryResponse> => {
    const response = await axiosInstance.get<NavbarCategoryResponse>("/api/categories/navbar");
    return response.data;
  },
};