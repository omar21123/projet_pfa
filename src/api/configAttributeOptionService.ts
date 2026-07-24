import axiosInstance from "./axiosInstances";
import type {
  ConfigAttributeOption,
  CreateConfigAttributeOptionPayload,
  UpdateConfigAttributeOptionPayload,
  OptionPublicFilters,
  OptionAdminFilters,
  PaginatedApiResponse,
  ApiResponse,
} from "../types/config_attribute_option";

export const configAttributeOptionService = {
  /** Liste légère d'options actives */
  fetchPublic: async (filters: OptionPublicFilters = {}) => {
    const response = await axiosInstance.get<PaginatedApiResponse<ConfigAttributeOption>>(
      "/api/config-attribute-options",
      { params: filters }
    );
    return response.data;
  },

  /** Récupérer toutes les options actives d'un attribut donné */
  fetchByAttributeId: async (attributeId: number) => {
    const response = await axiosInstance.get<ApiResponse<ConfigAttributeOption[]>>(
      `/api/config-attribute-options/by-attribute/${attributeId}`
    );
    return response.data;
  },

  /** Vérifier si une option existe par son libellé pour un attribut */
  checkExists: async (attributeID: number, label: string) => {
    const response = await axiosInstance.get<{ success: boolean; exists: boolean }>(
      "/api/config-attribute-options/exists",
      { params: { attributeID, label } }
    );
    return response.data;
  },

  /** Créer une nouvelle option d'attribut */
  create: async (payload: CreateConfigAttributeOptionPayload) => {
    const response = await axiosInstance.post<ApiResponse<ConfigAttributeOption>>(
      "/api/config-attribute-options/create",
      payload
    );
    return response.data;
  },

  /** Mettre à jour une option */
  update: async (id: number, payload: UpdateConfigAttributeOptionPayload) => {
    const response = await axiosInstance.put<ApiResponse<null>>(
      `/api/config-attribute-options/${id}`,
      payload
    );
    return response.data;
  },

  /** Activer une option */
  enable: async (id: number) => {
    const response = await axiosInstance.put<ApiResponse<null>>(
      `/api/config-attribute-options/${id}/enable`
    );
    return response.data;
  },

  /** Désactiver une option */
  disable: async (id: number) => {
    const response = await axiosInstance.put<ApiResponse<null>>(
      `/api/config-attribute-options/${id}/disable`
    );
    return response.data;
  },

  /** Liste administration avec filtres et pagination */
  fetchAdmin: async (filters: OptionAdminFilters = {}) => {
    const response = await axiosInstance.get<PaginatedApiResponse<ConfigAttributeOption>>(
      "/api/config-attribute-options/admin",
      { params: filters }
    );
    return response.data;
  },
};