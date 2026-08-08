import { useQuery } from "@tanstack/react-query";
import { productRecommendationsApi } from "@/api/productRecommendationsApi";
import type {
  GetRecommendationsParams,
  LoadMoreParams,
  NewLoadMoreParams,
  PaginatedLoadMoreResponse,
} from "@/types/recommendations";

const recommendationsQueryKey = ["product-recommendations"] as const;

export function useProductRecommendations(params: GetRecommendationsParams = {}) {
  return useQuery({
    queryKey: [...recommendationsQueryKey, "all", params],
    queryFn: () => productRecommendationsApi.getRecommendations(params),
  });
}

function useProductLoadMore(
  key: string,
  params: LoadMoreParams,
  queryFn: () => Promise<PaginatedLoadMoreResponse>,
) {
  return useQuery({
    queryKey: [...recommendationsQueryKey, key, params],
    queryFn,
  });
}

export function useMostSoldLoadMore(params: LoadMoreParams = {}) {
  return useProductLoadMore("most-sold", params, () =>
    productRecommendationsApi.getMostSoldLoadMore(params),
  );
}

export function useMostViewedLoadMore(params: LoadMoreParams = {}) {
  return useProductLoadMore("most-viewed", params, () =>
    productRecommendationsApi.getMostViewedLoadMore(params),
  );
}

export function useMostPromotedLoadMore(params: LoadMoreParams = {}) {
  return useProductLoadMore("most-promoted", params, () =>
    productRecommendationsApi.getMostPromotedLoadMore(params),
  );
}

export function useTrendingLoadMore(params: LoadMoreParams = {}) {
  return useProductLoadMore("trending", params, () =>
    productRecommendationsApi.getTrendingLoadMore(params),
  );
}

export function useLastActivityLoadMore(params: LoadMoreParams = {}) {
  return useProductLoadMore("last-activity", params, () =>
    productRecommendationsApi.getLastActivityLoadMore(params),
  );
}

export function usePopularInRegionLoadMore(params: LoadMoreParams = {}) {
  return useProductLoadMore("popular-in-region", params, () =>
    productRecommendationsApi.getPopularInRegionLoadMore(params),
  );
}

export function useNewProductsLoadMore(params: NewLoadMoreParams = {}) {
  return useProductLoadMore("new", params, () => productRecommendationsApi.getNewLoadMore(params));
}
