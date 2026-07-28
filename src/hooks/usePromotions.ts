import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { promotionsApi } from "@/api/promotionsApi";
import type { CreateProductPromotionPayload } from "@/types/promotion";

export function usePromotionLookups() {
  return useQuery({
    queryKey: ["promotion-lookups"],
    queryFn: promotionsApi.getLookups,
  });
}

export function useCreateProductPromotion() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CreateProductPromotionPayload) =>
      promotionsApi.createForProduct(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["products"] });
    },
  });
}