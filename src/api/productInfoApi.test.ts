import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiClient } from "./client";
import { fetchProductInfo } from "./productInfoApi";

vi.mock("./client", () => ({
  apiClient: {
    post: vi.fn(),
  },
}));

describe("fetchProductInfo", () => {
  beforeEach(() => {
    vi.mocked(apiClient.post).mockReset();
  });

  it("calls the public product info endpoint with the documented payload", async () => {
    const response = {
      success: true,
      data: {
        categories: [],
        allowed_payments: [],
        attributes: [],
        combinations: [],
        tags: [],
      },
    };
    vi.mocked(apiClient.post).mockResolvedValue({ data: response } as never);

    await expect(
      fetchProductInfo({
        ProductID: 12345,
        FromSearch: true,
        SearchTerm: "wireless headphones",
      }),
    ).resolves.toEqual(response);

    expect(apiClient.post).toHaveBeenCalledWith("/api/products/info", {
      ProductID: 12345,
      FromSearch: true,
      SearchTerm: "wireless headphones",
    });
  });
});
