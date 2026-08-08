import type { RecommendedProduct } from "@/types/recommendations";

type RawRecommendationProduct = RecommendedProduct & Record<string, unknown>;

const firstValue = (product: RawRecommendationProduct, keys: string[]) =>
  keys.map((key) => product[key]).find((value) => value !== undefined && value !== null);

const toNumber = (value: unknown): number | undefined => {
  const number = typeof value === "number" ? value : Number(value);
  return Number.isFinite(number) ? number : undefined;
};

const toBoolean = (value: unknown): boolean => {
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value !== 0;
  if (typeof value === "string") return !["", "0", "false", "no"].includes(value.toLowerCase());
  return Boolean(value);
};

const hasValue = (value: unknown): boolean => {
  if (value === undefined || value === null || value === false || value === 0 || value === "") {
    return false;
  }
  if (Array.isArray(value)) return value.length > 0;
  return true;
};

export interface RecommendationCommercialInfo {
  originalPrice?: number;
  discountPercentage?: number;
  hasPromotion: boolean;
  isBoosted: boolean;
  isTopSale: boolean;
}

export function getRecommendationCommercialInfo(
  product: RecommendedProduct,
  section: string,
): RecommendationCommercialInfo {
  const raw = product as RawRecommendationProduct;
  const originalPrice = toNumber(
    firstValue(raw, [
      "OriginalPrice",
      "original_price",
      "OldPrice",
      "old_price",
      "CompareAtPrice",
      "compare_at_price",
    ]),
  );
  const explicitDiscount = toNumber(
    firstValue(raw, [
      "DiscountPercentage",
      "discount_percentage",
      "DiscountPercent",
      "discount_percent",
    ]),
  );
  const calculatedDiscount =
    originalPrice && originalPrice > product.Price
      ? Math.round(((originalPrice - product.Price) / originalPrice) * 100)
      : undefined;
  const hasPromotion = [
    "Promotion",
    "promotion",
    "ActivePromotion",
    "active_promotion",
    "ProductPromotion",
    "product_promotion",
    "Promotions",
    "promotions",
    "HasPromotion",
    "has_promotion",
    "IsPromotion",
    "is_promotion",
    "PromotionID",
    "promotion_id",
  ].some((key) => hasValue(raw[key]));
  const isBoosted = [
    "IsBoosted",
    "is_boosted",
    "IsBoostedProduct",
    "is_boosted_product",
    "Boosted",
    "boosted",
    "IsSponsored",
    "is_sponsored",
    "IsPromoted",
    "is_promoted",
    "Sponsored",
    "sponsored",
  ].some((key) => toBoolean(raw[key]));
  const isTopSale =
    section === "MostSold" || toBoolean(firstValue(raw, ["IsTopSale", "is_top_sale"]));
  const hasPriceDiscount =
    Boolean(explicitDiscount && explicitDiscount > 0) || Boolean(calculatedDiscount);

  return {
    originalPrice: hasPromotion || hasPriceDiscount ? originalPrice : undefined,
    discountPercentage:
      hasPromotion || hasPriceDiscount ? (explicitDiscount ?? calculatedDiscount) : undefined,
    hasPromotion: hasPromotion || section === "Promotions",
    isBoosted,
    isTopSale,
  };
}
