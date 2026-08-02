export type DiscountTypeCode = "PERCENTAGE" | "FIXED_AMOUNT";
export type PromotionScopeCode = "PRODUCT" | "CATEGORY";
export type PromotionStatusCode = string;

export interface PromotionLookupItem {
  id: number;
  code: string;
  label: string;
}

export interface PromotionLookups {
  discount_types: PromotionLookupItem[];
  scope_types: PromotionLookupItem[];
  statuses: PromotionLookupItem[];
}

export interface PromotionReference {
  code: string;
  label: string;
}

export interface Promotion {
  promotion_id: number;
  vendor_id: number | null;
  name: string;
  description: string | null;
  promo_code: string | null;
  discount_type: PromotionReference;
  discount_value: number;
  max_discount_amount: number | null;
  min_order_amount: number | null;
  scope_type: PromotionReference;
  target_product_id: number | null;
  target_category_id: number | null;
  usage_limit_total: number | null;
  usage_limit_per_user: number | null;
  usage_count: number;
  start_date: string;
  end_date: string;
  status: PromotionReference;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  product_name?: string | null;
  category_name?: string | null;
}

export type PromotionDetail = Promotion;

export interface PromotionListMeta {
  page: number;
  page_size: number;
  has_more: boolean;
}

export interface PromotionListResponse {
  success: boolean;
  data: Promotion[];
  meta: PromotionListMeta;
}

export interface PromotionResponse {
  success: boolean;
  data: Promotion;
}

export interface PromotionMutationResponse {
  success: boolean;
  message?: string;
  data: Record<string, unknown>;
}

export interface PromotionMessageResponse {
  success: boolean;
  message: string;
}

export interface CreateProductPromotionPayload {
  ProductID: number;
  Name: string;
  Description?: string | null;
  PromoCode?: string | null;
  DiscountTypeCode: DiscountTypeCode;
  DiscountValue: number;
  MaxDiscountAmount?: number | null;
  MinOrderAmount?: number | null;
  UsageLimitTotal?: number | null;
  UsageLimitPerUser?: number | null;
  StartDate: string;
  EndDate: string;
}

export interface CreateCategoryPromotionPayload
  extends Omit<CreateProductPromotionPayload, "ProductID"> {
  CategoryID: number;
}

export type UpdatePromotionPayload = Partial<
  Omit<CreateProductPromotionPayload, "ProductID">
>;

export interface PromotionListParams {
  status?: string;
  scope?: PromotionScopeCode;
  is_active?: 0 | 1;
  page?: number;
  page_size?: number;
}
