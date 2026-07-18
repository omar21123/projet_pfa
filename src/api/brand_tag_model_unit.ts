import axiosInstance from "./axiosInstances"; // <-- On importe l'instance officielle avec gestion de token intégrée
import type {
  ApiResponse,
  Tag,
  Unit,
  Brand,
  ProductModel,
  Country,
  AdminFilters,
} from "../types/brand_tag_model_unit";

export const adminService = {
  // 1. TAGS
  tags: {
    fetch: async (params: AdminFilters) => {
      const res = await axiosInstance.get<ApiResponse<Tag[]>>("/api/tags", { params });
      return res.data;
    },
    create: async (payload: { Name: string; Color?: string; Description?: string }) => {
      const res = await axiosInstance.post<ApiResponse<Tag>>("/api/tags/create", payload);
      return res.data;
    },
    createByName: async (payload: { Name: string }) => {
      const res = await axiosInstance.post<ApiResponse<{ id: number }>>(
        "/api/auth/me", // Ajusté selon vos routes réelles si nécessaire
        payload,
      );
      return res.data;
    },
    disable: async (id: number) => {
      const res = await axiosInstance.post<ApiResponse<any>>(`/api/tags/${id}/disable`);
      return res.data;
    },
  },

  // 2. UNITÉS
  units: {
    fetch: async (params: AdminFilters) => {
      const res = await axiosInstance.get<ApiResponse<Unit[]>>("/api/units/admin", { params });
      return res.data;
    },
    create: async (payload: { Name: string; Symbol: string; DisplayOrder?: number | null }) => {
      const res = await axiosInstance.post<ApiResponse<Unit>>("/api/units/create", payload);
      return res.data;
    },
    update: async (
      id: number,
      payload: { Name: string; Symbol: string; DisplayOrder?: number | null },
    ) => {
      const res = await axiosInstance.put<ApiResponse<any>>(`/api/units/${id}`, payload);
      return res.data;
    },
    enable: async (id: number) => {
      const res = await axiosInstance.put<ApiResponse<any>>(`/api/units/${id}/enable`);
      return res.data;
    },
    disable: async (id: number) => {
      const res = await axiosInstance.put<ApiResponse<any>>(`/api/units/${id}/disable`);
      return res.data;
    },
  },

  // 3. MARQUES
  brands: {
    fetch: async (params: AdminFilters) => {
      const res = await axiosInstance.get<ApiResponse<Brand[]>>("/api/brands/admin", { params });
      return res.data;
    },
    create: async (formData: FormData) => {
      const res = await axiosInstance.post<ApiResponse<Brand>>("/api/brands/create", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      return res.data;
    },
    enable: async (id: number) => {
      const res = await axiosInstance.put<ApiResponse<any>>(`/api/brands/${id}/enable`);
      return res.data;
    },
    disable: async (id: number) => {
      const res = await axiosInstance.put<ApiResponse<any>>(`/api/brands/${id}/disable`);
      return res.data;
    },
  },

  // 4. MODÈLES DE PRODUITS
  models: {
    fetchAdmin: async (params: AdminFilters) => {
      const res = await axiosInstance.get<ApiResponse<ProductModel[]>>("/api/models/admin", { params });
      return res.data;
    },
    create: async (payload: {
      BrandID: number;
      Name: string;
      Code?: string | null;
      Description?: string | null;
      ReleaseYear?: number | null;
    }) => {
      const res = await axiosInstance.post<ApiResponse<ProductModel>>("/api/models/create", payload);
      return res.data;
    },
    update: async (
      id: number,
      payload: {
        Name: string;
        Code?: string | null;
        Description?: string | null;
        ReleaseYear?: number | null;
      },
    ) => {
      const res = await axiosInstance.put<ApiResponse<any>>(`/api/models/${id}`, payload);
      return res.data;
    },
    enable: async (id: number) => {
      const res = await axiosInstance.put<ApiResponse<any>>(`/api/models/${id}/enable`);
      return res.data;
    },
    disable: async (id: number) => {
      const res = await axiosInstance.put<ApiResponse<any>>(`/api/models/${id}/disable`);
      return res.data;
    },
  },

  // 5. PAYS
  general: {
    getCountries: async () => {
      const res = await axiosInstance.get<ApiResponse<Country[]>>("/api/countries");
      return res.data;
    },
  },
};