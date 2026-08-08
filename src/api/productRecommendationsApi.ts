import { apiClient } from "./client";
import type {
  GetRecommendationsParams,
  LoadMoreParams,
  NewLoadMoreParams,
  PaginatedLoadMoreResponse,
  ProductRecommendationsResponse,
  RecommendedProduct,
} from "@/types/recommendations";

const withRecommendationDefaults = (
  params: GetRecommendationsParams = {},
): GetRecommendationsParams & { limit: number } => {
  const { limit = 20, ...rest } = params;
  return { limit, ...rest };
};

const withLoadMoreDefaults = (
  params: LoadMoreParams = {},
): LoadMoreParams & { page: number; page_size: number } => {
  const { page = 1, page_size = 20, ...rest } = params;
  return { page, page_size, ...rest };
};

export const productRecommendationsApi = {
  getRecommendations: async (
    params: GetRecommendationsParams = {},
  ): Promise<ProductRecommendationsResponse> => {
    const { data } = await apiClient.get<ProductRecommendationsResponse>(
      "/api/products/recommendations",
      { params: withRecommendationDefaults(params) },
    );

    return data;
  },

  getMostSoldLoadMore: async (params: LoadMoreParams = {}): Promise<PaginatedLoadMoreResponse> =>
    getLoadMore("/api/products/most-sold/load-more", params),

  getMostViewedLoadMore: async (params: LoadMoreParams = {}): Promise<PaginatedLoadMoreResponse> =>
    getLoadMore("/api/products/most-viewed/load-more", params),

  getMostPromotedLoadMore: async (
    params: LoadMoreParams = {},
  ): Promise<PaginatedLoadMoreResponse> =>
    getLoadMore("/api/products/most-promoted/load-more", params),

  getTrendingLoadMore: async (params: LoadMoreParams = {}): Promise<PaginatedLoadMoreResponse> =>
    getLoadMore("/api/products/trending/load-more", params),

  getLastActivityLoadMore: async (
    params: LoadMoreParams = {},
  ): Promise<PaginatedLoadMoreResponse> =>
    getLoadMore("/api/products/last-activity/load-more", params),

  getPopularInRegionLoadMore: async (
    params: LoadMoreParams = {},
  ): Promise<PaginatedLoadMoreResponse> =>
    getLoadMore("/api/products/popular-in-region/load-more", params),

  getNewLoadMore: async (params: NewLoadMoreParams = {}): Promise<PaginatedLoadMoreResponse> => {
    const { data } = await apiClient.get<PaginatedLoadMoreResponse>("/api/products/new/load-more", {
      params: withNewLoadMoreDefaults(params),
    });

    return data;
  },
};

function withNewLoadMoreDefaults(
  params: NewLoadMoreParams = {},
): NewLoadMoreParams & { page: number; page_size: number; days_back: number } {
  const { days_back = 7, ...rest } = params;
  return { ...withLoadMoreDefaults(rest), days_back };
}

async function getLoadMore(
  url: string,
  params: LoadMoreParams,
): Promise<PaginatedLoadMoreResponse<RecommendedProduct>> {
  const { data } = await apiClient.get<PaginatedLoadMoreResponse<RecommendedProduct>>(url, {
    params: withLoadMoreDefaults(params),
  });

  return data;
}

export const productRecommendationApi = productRecommendationsApi;
