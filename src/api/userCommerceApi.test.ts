import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiClient } from "./client";
import { addCartItem, getCart, removeCartItem } from "../features/cart/cart.api";
import { addFavorite, getFavorites, removeFavorite } from "./favorites.api";
import {
  addWishlistItem,
  createWishlist,
  deleteWishlist,
  getWishlists,
  removeWishlistItem,
} from "./wishlist.api";

vi.mock("./client", () => ({
  apiClient: {
    delete: vi.fn(),
    get: vi.fn(),
    post: vi.fn(),
  },
}));

describe("wishlist, cart and favorites APIs", () => {
  beforeEach(() => {
    vi.mocked(apiClient.delete).mockResolvedValue({ data: { success: true } } as never);
    vi.mocked(apiClient.get).mockResolvedValue({ data: { success: true, data: [] } } as never);
    vi.mocked(apiClient.post).mockResolvedValue({ data: { success: true } } as never);
    vi.clearAllMocks();
  });

  it("uses the documented wishlist routes and payloads", async () => {
    await getWishlists();
    await createWishlist({ name: "Cadeaux" });
    await addWishlistItem(7, { product_id: 123 });
    await removeWishlistItem(42);
    await deleteWishlist(7);

    expect(apiClient.get).toHaveBeenCalledWith("/api/wishlists");
    expect(apiClient.post).toHaveBeenCalledWith("/api/wishlists", { name: "Cadeaux" });
    expect(apiClient.post).toHaveBeenCalledWith("/api/wishlists/7/items", {
      product_id: 123,
    });
    expect(apiClient.delete).toHaveBeenCalledWith("/api/wishlists/items/42");
    expect(apiClient.delete).toHaveBeenCalledWith("/api/wishlists/7");
  });

  it("uses the documented cart routes and request bodies", async () => {
    await getCart();
    await addCartItem({
      productID: 12345,
      FromSearch: true,
      SearchTerm: "headphones",
      CompositionID: 10,
      UnitPrice: 19.99,
    });
    await removeCartItem({ productID: 12345, CompositionID: 10 });

    expect(apiClient.get).toHaveBeenCalledWith("/api/cart");
    expect(apiClient.post).toHaveBeenCalledWith("/api/cart/items", {
      productID: 12345,
      FromSearch: true,
      SearchTerm: "headphones",
      CompositionID: 10,
      UnitPrice: 19.99,
    });
    expect(apiClient.delete).toHaveBeenCalledWith("/api/cart/items", {
      data: { productID: 12345, CompositionID: 10 },
    });
  });

  it("uses the documented favorites routes", async () => {
    await getFavorites();
    await addFavorite({ product_id: 123 });
    await removeFavorite(123);

    expect(apiClient.get).toHaveBeenCalledWith("/api/favorites");
    expect(apiClient.post).toHaveBeenCalledWith("/api/favorites", { product_id: 123 });
    expect(apiClient.delete).toHaveBeenCalledWith("/api/favorites/123");
  });
});
