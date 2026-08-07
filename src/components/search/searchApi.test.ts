import { beforeEach, describe, expect, it, vi } from "vitest";
import axiosInstance from "@/api/axiosInstances";
import { fetchSearchProducts } from "./searchApi";

vi.mock("@/api/axiosInstances", () => ({
  default: {
    get: vi.fn(),
  },
  getAuthAccessToken: vi.fn(),
}));

describe("fetchSearchProducts", () => {
  beforeEach(() => {
    vi.mocked(axiosInstance.get).mockReset();
  });

  it("normalizes the product response and pagination metadata", async () => {
    vi.mocked(axiosInstance.get).mockResolvedValue({
      data: {
        success: true,
        data: [
          {
            ProductID: 274,
            ProductName: "Chaussures Max 239",
            ProductImage: null,
            Description: "Produit de test",
            Price: 927.79,
            Brand: { name: "Lumen Kids", logo: null },
            ModelName: "Gamma-33",
            TotalWishlist: 1,
            TotalLikes: 0,
            TotalOrders: 4,
            IsLiked: false,
            IsWishedList: false,
          },
        ],
        meta: { page: 1, page_size: 20, total: 36, has_more: true },
      },
    } as never);

    await expect(fetchSearchProducts(" Chaussures ")).resolves.toEqual({
      products: [
        expect.objectContaining({
          ProductID: 274,
          ProductName: "Chaussures Max 239",
          Price: 927.79,
        }),
      ],
      currentPage: 1,
      pageSize: 20,
      total: 36,
      hasMore: true,
    });

    expect(axiosInstance.get).toHaveBeenCalledWith("/api/search", {
      params: { q: "Chaussures", page: 1, page_size: 20 },
    });
  });

  it("does not call the API for an empty query", async () => {
    await expect(fetchSearchProducts("   ")).resolves.toEqual({
      products: [],
      currentPage: 1,
      pageSize: 20,
      total: 0,
      hasMore: false,
    });

    expect(axiosInstance.get).not.toHaveBeenCalled();
  });
});
