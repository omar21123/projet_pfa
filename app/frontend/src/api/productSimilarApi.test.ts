import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiClient } from "./client";
import { productSimilarApi } from "./productSimilarApi";

vi.mock("./client", () => ({
  apiClient: {
    get: vi.fn(),
  },
}));

describe("productSimilarApi", () => {
  beforeEach(() => {
    vi.mocked(apiClient.get).mockReset();
    vi.mocked(apiClient.get).mockResolvedValue({ data: { success: true, data: {} } } as never);
  });

  it("calls the similar-products endpoint with its default limit", async () => {
    await productSimilarApi.get(547);

    expect(apiClient.get).toHaveBeenCalledWith("/api/products/547/similar", {
      params: { limit: 10 },
    });
  });

  it("passes a custom limit and returns the API response", async () => {
    const response = {
      success: true,
      data: {
        SimilarProducts: [],
        SimilarInBrandsOrModels: [],
        SimilarInCategories: [],
      },
    };
    vi.mocked(apiClient.get).mockResolvedValue({ data: response } as never);

    await expect(productSimilarApi.get(547, 5)).resolves.toEqual(response);
    expect(apiClient.get).toHaveBeenCalledWith("/api/products/547/similar", {
      params: { limit: 5 },
    });
  });
});
