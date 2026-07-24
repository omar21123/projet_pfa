// src/api/moderationApi.ts

import { apiClient } from "./client";
import {
  ApiResponse,
  ProductListItem,
  ProductDetails,
  RefuseResponse,
} from "../types/moderation";

export const moderationApi = {
  /**
   * Liste des produits à modérer
   */
  getProducts: async (
    params: Record<string, any>
  ): Promise<ApiResponse<ProductListItem[]>> => {
    const cleanedParams = Object.fromEntries(
      Object.entries(params).filter(
        ([_, value]) =>
          value !== "" &&
          value !== "any" &&
          value !== null &&
          value !== undefined
      )
    );

    const { data } = await apiClient.get("/api/products/admin", {
      params: cleanedParams,
    });

    return data;
  },

  /**
   * Détails d'un produit
   */
 /**
   * Détails d'un produit (Route Admin)
   */
  getProductDetails: async (
    id: number | string
  ): Promise<ApiResponse<any>> => {
    // Utilisation de la route d'administration au lieu de la route publique
    const { data } = await apiClient.get(`/api/products/${id}`);

    return data;
  },

  /**
   * Validation d'un produit
   */
  validateProduct: async (
    id: number,
    notes: string | null
  ): Promise<ApiResponse<null>> => {
    const { data } = await apiClient.patch(
      `/api/products/${id}/validate`,
      {
        ValidationNotes: notes,
      }
    );

    return data;
  },

  /**
   * Refus d'un produit
   */
  refuseProduct: async (
    id: number,
    notes: string
  ): Promise<RefuseResponse> => {
    const { data } = await apiClient.patch(
      `/api/products/${id}/refuse`,
      {
        RefuseNotes: notes,
      }
    );

    return data;
  },

  /**
   * Blocage d'un produit
   */
  blockProduct: async (
    id: number,
    notes: string
  ): Promise<ApiResponse<null>> => {
    const { data } = await apiClient.patch(
      `/api/products/${id}/block`,
      {
        BlockedNotes: notes,
      }
    );

    return data;
  },
};