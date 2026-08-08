import { apiClient } from "./client";
import type { SimilarProductsResponse } from "@/types/similar-products";

export const productSimilarApi = {
  get: async (productId: number, limit = 10): Promise<SimilarProductsResponse> => {
    const { data } = await apiClient.get<SimilarProductsResponse>(
      `/api/products/${productId}/similar`,
      { params: { limit } },
    );

    return data;
  },
};

export const getSimilarProducts = productSimilarApi.get;
