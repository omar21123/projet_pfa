// src/api/config_attribute_service.ts

import axiosInstance from "./axiosInstances";
import type { 
  ApiResponse, 
  ApiResponseWithPagination, 
  ProductsConfigAttribute, 
  AttributeFilters,
  ConfigAttributeOption,
  OptionFilters
} from "../types/config_attribute";

export const configAttributeService = {
  
  // ==========================================
  // 1. ATTRIBUTS DE CONFIGURATION
  // ==========================================
  attributes: {
    // Liste légère (Publique / Vendeur)
    fetchPublic: async (filters: AttributeFilters) => {
      const res = await axiosInstance.get<ApiResponseWithPagination<ProductsConfigAttribute[]>>(
        "/api/products-config-attributes", 
        { params: filters }
      );
      return res.data;
    },

    // Liste complète (Admin uniquement)
    fetchAdmin: async (filters: AttributeFilters) => {
      const res = await axiosInstance.get<ApiResponseWithPagination<ProductsConfigAttribute[]>>(
        "/api/products-config-attributes/admin", 
        { params: filters }
      );
      return res.data;
    },

    create: async (data: Partial<ProductsConfigAttribute>) => {
      const res = await axiosInstance.post<ApiResponse<ProductsConfigAttribute>>(
        "/api/products-config-attributes/create", 
        data
      );
      return res.data;
    },

    update: async (id: number, data: Partial<ProductsConfigAttribute>) => {
      const res = await axiosInstance.put<ApiResponse<null>>(
        `/api/products-config-attributes/${id}`, 
        data
      );
      return res.data;
    },

    enable: async (id: number) => {
      const res = await axiosInstance.put<ApiResponse<null>>(`/api/products-config-attributes/${id}/enable`);
      return res.data;
    },

    disable: async (id: number) => {
      const res = await axiosInstance.put<ApiResponse<null>>(`/api/products-config-attributes/${id}/disable`);
      return res.data;
    },
  },

  // ==========================================
  // 2. OPTIONS D'ATTRIBUTS
  // ==========================================
  options: {
    // Liste légère globale
    fetchPublic: async (filters: OptionFilters) => {
      const res = await axiosInstance.get<ApiResponseWithPagination<ConfigAttributeOption[]>>(
        "/api/config-attribute-options", 
        { params: filters }
      );
      return res.data;
    },

    // Récupérer TOUTES les options d'un attribut spécifique (CRUCIAL POUR L'AJOUT PRODUIT VENDOR)
    fetchByAttributeId: async (attributeId: number) => {
      const res = await axiosInstance.get<ApiResponse<ConfigAttributeOption[]>>(
        `/api/config-attribute-options/by-attribute/${attributeId}`
      );
      return res.data;
    },

    // Liste complète (Admin)
    fetchAdmin: async (filters: OptionFilters) => {
      const res = await axiosInstance.get<ApiResponseWithPagination<ConfigAttributeOption[]>>(
        "/api/config-attribute-options/admin", 
        { params: filters }
      );
      return res.data;
    },

    create: async (data: Partial<ConfigAttributeOption>) => {
      const res = await axiosInstance.post<ApiResponse<ConfigAttributeOption>>(
        "/api/config-attribute-options/create", 
        data
      );
      return res.data;
    },

    update: async (id: number, data: Partial<ConfigAttributeOption>) => {
      const res = await axiosInstance.put<ApiResponse<null>>(
        `/api/config-attribute-options/${id}`, 
        data
      );
      return res.data;
    },

    enable: async (id: number) => {
      const res = await axiosInstance.put<ApiResponse<null>>(`/api/config-attribute-options/${id}/enable`);
      return res.data;
    },

    disable: async (id: number) => {
      const res = await axiosInstance.put<ApiResponse<null>>(`/api/config-attribute-options/${id}/disable`);
      return res.data;
    },
  }
};