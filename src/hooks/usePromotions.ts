import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { promotionsApi } from "@/api/promotionsApi";
import type {
  CreateCategoryPromotionPayload,
  CreateProductPromotionPayload,
  PromotionListParams,
  UpdatePromotionPayload,
} from "@/types/promotion";

const promotionsQueryKey = ["promotions"];

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
      queryClient.invalidateQueries({ queryKey: promotionsQueryKey });
      queryClient.invalidateQueries({ queryKey: ["products"] });
    },
  });
}

export function usePromotionList(params: PromotionListParams, enabled = true) {
  return useQuery({
    queryKey: [...promotionsQueryKey, "list", params],
    queryFn: () => promotionsApi.getAll(params),
    enabled,
  });
}

export function usePromotion(promotionId: number | null) {
  return useQuery({
    queryKey: [...promotionsQueryKey, promotionId],
    queryFn: () => promotionsApi.getById(promotionId as number),
    enabled: promotionId !== null,
  });
}

export function useProductPromotions(productId: number | null) {
  return useQuery({
    queryKey: [...promotionsQueryKey, "product", productId],
    queryFn: () => promotionsApi.getForProduct(productId as number),
    enabled: productId !== null,
  });
}

export function useCreateCategoryPromotion() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: CreateCategoryPromotionPayload) => promotionsApi.createForCategory(payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: promotionsQueryKey }),
  });
}

export function useUpdatePromotion() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ promotionId, payload }: { promotionId: number; payload: UpdatePromotionPayload }) =>
      promotionsApi.updatePromotion(promotionId, payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: promotionsQueryKey }),
  });
}

export function useDeletePromotion() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (promotionId: number) => promotionsApi.deletePromotion(promotionId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: promotionsQueryKey }),
  });
}

export function useDeactivatePromotion() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (promotionId: number) => promotionsApi.deactivate(promotionId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: promotionsQueryKey }),
  });
}
