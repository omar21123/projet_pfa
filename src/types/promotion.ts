export type DiscountTypeCode = 'PERCENTAGE' | 'FIXED_AMOUNT';

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