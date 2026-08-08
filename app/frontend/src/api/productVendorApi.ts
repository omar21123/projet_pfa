import axiosInstance from "./axiosInstances";
import {
  VendorProductFilters,
  VendorProductsResponse,
  VendorProductDetail,
} from "@/types/prodcut";
import { moderationApi } from "./moderationApi";

export const getVendorProducts = async (
  filters: VendorProductFilters,
): Promise<VendorProductsResponse> => {
  const params = new URLSearchParams();

  if (filters.search) params.append("search", filters.search);
  if (filters.status !== undefined && filters.status !== null) {
    params.append("status", filters.status.toString());
  }
  if (filters.is_active !== undefined) {
    params.append("is_active", filters.is_active.toString());
  }
  if (filters.is_blocked !== undefined) {
    params.append("is_blocked", filters.is_blocked.toString());
  }
  params.append("page", filters.page.toString());
  params.append("per_page", filters.per_page.toString());

  const response = await axiosInstance.get<VendorProductsResponse>(
    `/api/products/vendor/me?${params.toString()}`,
  );

  return response.data;
};

export const getVendorProductDetail = async (id: number): Promise<VendorProductDetail> => {
  const res = await moderationApi.getProductDetails(id);
  const details = res.data.details;
  const firstImage = res.data.images?.[0]?.url ?? null;
  return {
    ...details,
    main_image: firstImage,
    images: res.data.images,
    videos: res.data.videos,
  };
};
