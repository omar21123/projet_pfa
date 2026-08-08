import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiClient } from "./client";
import { productRecommendationsApi } from "./productRecommendationsApi";

vi.mock("./client", () => ({
  apiClient: {
    get: vi.fn(),
  },
}));

describe("productRecommendationsApi", () => {
  beforeEach(() => {
    vi.mocked(apiClient.get).mockReset();
    vi.mocked(apiClient.get).mockResolvedValue({ data: {} } as never);
  });

  it("gets all recommendation groups with documented defaults", async () => {
    const response = { success: true, data: { MostSold: [] } };
    vi.mocked(apiClient.get).mockResolvedValue({ data: response } as never);

    await expect(productRecommendationsApi.getRecommendations()).resolves.toEqual(response);

    expect(apiClient.get).toHaveBeenCalledWith("/api/products/recommendations", {
      params: { limit: 20 },
    });
  });

  it("passes recommendation filters", async () => {
    await productRecommendationsApi.getRecommendations({ limit: 10, category_id: 4 });

    expect(apiClient.get).toHaveBeenCalledWith("/api/products/recommendations", {
      params: { limit: 10, category_id: 4 },
    });
  });

  it.each([
    ["getMostSoldLoadMore", "/api/products/most-sold/load-more"],
    ["getMostViewedLoadMore", "/api/products/most-viewed/load-more"],
    ["getMostPromotedLoadMore", "/api/products/most-promoted/load-more"],
    ["getTrendingLoadMore", "/api/products/trending/load-more"],
    ["getLastActivityLoadMore", "/api/products/last-activity/load-more"],
    ["getPopularInRegionLoadMore", "/api/products/popular-in-region/load-more"],
  ] as const)("calls %s", async (method, url) => {
    await productRecommendationsApi[method]({ page: 2, page_size: 5, category_id: 7 });

    expect(apiClient.get).toHaveBeenCalledWith(url, {
      params: { page: 2, page_size: 5, category_id: 7 },
    });
  });

  it("gets new products with the default lookback period", async () => {
    await productRecommendationsApi.getNewLoadMore();

    expect(apiClient.get).toHaveBeenCalledWith("/api/products/new/load-more", {
      params: { page: 1, page_size: 20, days_back: 7 },
    });
  });
});
