import axiosInstance from "@/api/axiosInstances";
import type {
  CreateCategoryPromotionPayload,
  CreateProductPromotionPayload,
  Promotion,
  PromotionListParams,
  PromotionListResponse,
  PromotionLookups,
  PromotionMessageResponse,
  PromotionMutationResponse,
  PromotionResponse,
  UpdatePromotionPayload,
} from "@/types/promotion";

/**
 * Normalise un objet promotion brut (PascalCase ou snake_case)
 * vers la structure unifiée au format snake_case attendue par le frontend.
 */
function normalizePromotion(raw: Record<string, any>): Promotion {
  if (!raw) return {} as Promotion;

  return {
    promotion_id: raw.promotion_id ?? raw.PromotionID ?? 0,
    vendor_id: raw.vendor_id ?? raw.VendorID ?? null,
    name: raw.name ?? raw.Name ?? "",
    description: raw.description ?? raw.Description ?? null,
    promo_code: raw.promo_code ?? raw.PromoCode ?? null,
    discount_type: raw.discount_type ?? raw.DiscountType ?? { code: "", label: "" },
    discount_value: Number(raw.discount_value ?? raw.DiscountValue ?? 0),
    max_discount_amount:
      (raw.max_discount_amount ?? raw.MaxDiscountAmount) !== null &&
      (raw.max_discount_amount ?? raw.MaxDiscountAmount) !== undefined
        ? Number(raw.max_discount_amount ?? raw.MaxDiscountAmount)
        : null,
    min_order_amount:
      (raw.min_order_amount ?? raw.MinOrderAmount) !== null &&
      (raw.min_order_amount ?? raw.MinOrderAmount) !== undefined
        ? Number(raw.min_order_amount ?? raw.MinOrderAmount)
        : null,
    scope_type: raw.scope_type ?? raw.ScopeType ?? { code: "", label: "" },
    target_product_id: raw.target_product_id ?? raw.TargetProductID ?? null,
    product_name: raw.product_name ?? raw.ProductName ?? null,
    target_category_id: raw.target_category_id ?? raw.TargetCategoryID ?? null,
    category_name: raw.category_name ?? raw.CategoryName ?? null,
    usage_limit_total: raw.usage_limit_total ?? raw.UsageLimitTotal ?? null,
    usage_limit_per_user: raw.usage_limit_per_user ?? raw.UsageLimitPerUser ?? null,
    usage_count: Number(raw.usage_count ?? raw.UsageCount ?? 0),
    start_date: raw.start_date ?? raw.StartDate ?? "",
    end_date: raw.end_date ?? raw.EndDate ?? "",
    status: raw.status ?? raw.Status ?? { code: "", label: "" },
    is_active: Boolean(raw.is_active ?? raw.IsActive),
    created_at: raw.created_at ?? raw.CreatedAt ?? "",
    updated_at: raw.updated_at ?? raw.UpdatedAt ?? "",
  };
}

export const promotionsApi = {
  getLookups: async (): Promise<PromotionLookups> => {
    const res = await axiosInstance.get<{ data: PromotionLookups }>("/api/promotions/lookups");
    return res.data.data;
  },

  createForProduct: async (payload: CreateProductPromotionPayload): Promise<PromotionMutationResponse> => {
    const res = await axiosInstance.post<PromotionMutationResponse>("/api/promotions/product", payload);
    return res.data;
  },

  createForCategory: async (
    payload: CreateCategoryPromotionPayload,
  ): Promise<PromotionMutationResponse> => {
    const res = await axiosInstance.post<PromotionMutationResponse>("/api/promotions/category", payload);
    return res.data;
  },

  getAll: async (params: PromotionListParams = {}): Promise<PromotionListResponse> => {
    const res = await axiosInstance.get("/api/promotions", { params });
    const rawItems = Array.isArray(res.data?.data) ? res.data.data : [];

    return {
      success: Boolean(res.data?.success),
      data: rawItems.map(normalizePromotion),
      meta: res.data?.meta ?? { page: 1, page_size: 20, has_more: false },
    };
  },

  getById: async (promotionId: number): Promise<PromotionResponse> => {
    const res = await axiosInstance.get(`/api/promotions/${promotionId}`);

    return {
      success: Boolean(res.data?.success),
      data: normalizePromotion(res.data?.data ?? {}),
    };
  },

  updatePromotion: async (
    promotionId: number,
    payload: UpdatePromotionPayload,
  ): Promise<PromotionMutationResponse> => {
    const res = await axiosInstance.put<PromotionMutationResponse>(`/api/promotions/${promotionId}`, payload);
    return res.data;
  },

  deletePromotion: async (promotionId: number): Promise<PromotionMessageResponse> => {
    const res = await axiosInstance.delete<PromotionMessageResponse>(`/api/promotions/${promotionId}`);
    return res.data;
  },

  deactivate: async (promotionId: number): Promise<PromotionMessageResponse> => {
    const res = await axiosInstance.patch<PromotionMessageResponse>(
      `/api/promotions/${promotionId}/deactivate`,
    );
    return res.data;
  },

  getForProduct: async (productId: number): Promise<Promotion[]> => {
    const res = await axiosInstance.get(`/api/promotions/product/${productId}`);
    const rawItems = Array.isArray(res.data?.data) ? res.data.data : [];
    return rawItems.map(normalizePromotion);
  },

  getForCategory: async (categoryId: number): Promise<Promotion[]> => {
    const res = await axiosInstance.get(`/api/promotions/category/${categoryId}`);
    const rawItems = Array.isArray(res.data?.data) ? res.data.data : [];
    return rawItems.map(normalizePromotion);
  },
};