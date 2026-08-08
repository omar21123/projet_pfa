import { describe, expect, it } from "vitest";
import { getRecommendationCommercialInfo } from "./recommendationProduct";
import type { RecommendedProduct } from "@/types/recommendations";

const product = (extra: Record<string, unknown> = {}): RecommendedProduct =>
  ({
    ProductID: 1,
    ProductName: "Produit test",
    ProductImage: null,
    Description: null,
    Price: 80,
    Brand: null,
    ModelName: null,
    TotalWishlist: 0,
    TotalLikes: 0,
    TotalOrders: 0,
    IsLiked: false,
    IsWishedList: false,
    ...extra,
  }) as RecommendedProduct;

describe("getRecommendationCommercialInfo", () => {
  it("does not invent promotion or top-sale badges", () => {
    expect(getRecommendationCommercialInfo(product(), "MostViewed")).toEqual({
      originalPrice: undefined,
      discountPercentage: undefined,
      hasPromotion: false,
      isBoosted: false,
      isTopSale: false,
    });
  });

  it("detects a product promotion, discount and boost from API fields", () => {
    expect(
      getRecommendationCommercialInfo(
        product({
          OriginalPrice: 100,
          Promotion: { name: "Offre spéciale" },
          IsBoosted: true,
        }),
        "Trending",
      ),
    ).toEqual({
      originalPrice: 100,
      discountPercentage: 20,
      hasPromotion: true,
      isBoosted: true,
      isTopSale: false,
    });
  });

  it("marks the most-sold section as top sale without claiming a promotion", () => {
    const result = getRecommendationCommercialInfo(product(), "MostSold");

    expect(result.isTopSale).toBe(true);
    expect(result.hasPromotion).toBe(false);
    expect(result.isBoosted).toBe(false);
  });
});
