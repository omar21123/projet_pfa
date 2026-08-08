import { apiClient } from "./client";
import type {
  ProductInfoRequest,
  ProductInfoResponse,
} from "@/types/product-info";

/**
 * Returns the complete public information for a product.
 *
 * Authentication is optional for this endpoint. The shared Axios client adds
 * the bearer token when a user is authenticated and sends no UserPublicID in
 * the body, so guests can call the same endpoint.
 */
export async function fetchProductInfo(
  payload: ProductInfoRequest,
): Promise<ProductInfoResponse> {
  const { data } = await apiClient.post<ProductInfoResponse>(
    "/api/products/info",
    payload,
  );

  return data;
}

export const productInfoApi = {
  get: fetchProductInfo,
};
