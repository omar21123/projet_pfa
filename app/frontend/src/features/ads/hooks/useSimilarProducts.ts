import { useQuery } from "@tanstack/react-query";
import { productSimilarApi } from "@/api/productSimilarApi";
import type { SimilarProductsResponse } from "@/types/similar-products";

export function useSimilarProducts(productId: number, limit = 10) {
  return useQuery<SimilarProductsResponse>({
    queryKey: ["similar-products", productId, limit],
    queryFn: () => productSimilarApi.get(productId, limit),
    enabled: Number.isFinite(productId) && productId > 0,
    staleTime: 1000 * 60 * 5,
  });
}
