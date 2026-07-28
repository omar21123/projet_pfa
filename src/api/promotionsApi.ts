import axiosInstance from "@/api/axiosInstances";
import type { PromotionLookups, CreateProductPromotionPayload } from "@/types/promotion";

export const promotionsApi = {
  getLookups: async (): Promise<PromotionLookups> => {
    const res = await axiosInstance.get("/api/promotions/lookups");
    return res.data.data;
  },

  createForProduct: async (payload: CreateProductPromotionPayload) => {
    const res = await axiosInstance.post("/api/promotions/product", payload);
    return res.data;
  },

  updatePromotion: async (promotionId: number, payload: Partial<CreateProductPromotionPayload>) => {
    const res = await axiosInstance.put(`/api/promotions/${promotionId}`, payload);
    return res.data;
  },
};