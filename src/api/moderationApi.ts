import { apiClient } from "./client";
import type {
  ApiResponse,
  ProductListItem,
  RefuseResponse,
} from "../types/moderation";
import type { VendorCombination, VendorCombinationDetail, VendorProductDetailResponse } from "@/types/prodcut";

export const moderationApi = {
  getProducts: async (
    params: Record<string, unknown>
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

  getProductDetails: async (
    id: number
  ): Promise<VendorProductDetailResponse> => {
    const { data } = await apiClient.get<VendorProductDetailResponse>(`/api/products/${id}`);
    return data;
  },

  validateProduct: async (
    id: number,
    notes: string | null
  ): Promise<ApiResponse<null>> => {
    const { data } = await apiClient.patch(
      `/api/products/${id}/validate`,
      { ValidationNotes: notes }
    );
    return data;
  },

  refuseProduct: async (
    id: number,
    notes: string
  ): Promise<RefuseResponse> => {
    const { data } = await apiClient.patch(
      `/api/products/${id}/refuse`,
      { RefuseNotes: notes }
    );
    return data;
  },

  blockProduct: async (
    id: number,
    notes: string
  ): Promise<ApiResponse<null>> => {
    const { data } = await apiClient.patch(
      `/api/products/${id}/block`,
      { BlockedNotes: notes }
    );
    return data;
  },

  getProductCombinations: async (
    productId: number
  ): Promise<{ data: VendorCombination[] }> => {
    const { data } = await apiClient.get<{ data: VendorCombination[] }>(
      `/api/products/${productId}/combinations`
    );
    return data;
  },

  getCombinationDetails: async (
    combinationId: number
  ): Promise<{ data: VendorCombinationDetail }> => {
    const { data } = await apiClient.get<{ data: VendorCombinationDetail }>(
      `/api/products/combinations/${combinationId}`
    );
    return data;
  },
};
