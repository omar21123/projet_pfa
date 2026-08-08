// src/api/product_service.ts
import axiosInstance from "./axiosInstances";
import type { ApiResponse } from "../types/config_attribute";

export interface ProductSubmitPayload {
  name: string;
  description: string;
  price: number;
  stock: number;
  category_id: number;
  brand_id: number;
  product_model_id: number;
  tag_ids: number[];
  // Structure pour lier les attributs choisis (ex: Couleur -> Rouge)
  attributes: {
    attribute_id: number;
    option_id: number;
  }[];
}

export const productService = {
  create: async (payload: ProductSubmitPayload) => {
    // 🔒 Route configurée spécifiquement pour le rôle VENDOR
    const res = await axiosInstance.post<ApiResponse<any>>("/api/products/create", payload);
    return res.data;
  }
};