import axiosInstance from "./axiosInstances"; // Réutilise ton instance configurée
import { AdminProfileResponse } from "../types/admin.types";

export const adminApi = {
  /**
   * Récupère le profil complet de l'administrateur connecté
   */
  getProfile: async (): Promise<AdminProfileResponse> => {
    const response = await axiosInstance.get<AdminProfileResponse>("/api/admin/profile");
    return response.data;
  }
};