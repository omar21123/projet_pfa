import { useQuery } from "@tanstack/react-query";
import { productInfoApi } from "@/api/productInfoApi";
import type {
  ProductInfoRequest,
  ProductInfoResponse,
} from "@/types/product-info";

export const useProductInfo = (
  payload: ProductInfoRequest,
  options?: { enabled?: boolean }
) => {
  return useQuery<ProductInfoResponse>({
    queryKey: [
      "product-info",
      payload.ProductID,
      payload.FromSearch,
      payload.SearchTerm,
    ],
    queryFn: () => productInfoApi.get(payload),
    enabled: (options?.enabled ?? true) && Boolean(payload.ProductID),
    staleTime: 1000 * 60 * 5, // 5 minutes
  });
};