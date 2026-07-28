import { apiClient } from "./client";

export interface CombinationPayload {
  sku?: string;
  price: number;
  compareAtPrice?: number | null;
  stock: number;
  isDefault: boolean;
  image?: File | null;
  options: { configName: string; optionName: string }[];
}

export interface CreateProductPayload {
  name: string;
  barcode: string;
  description?: string;
  basePrice: string;
  stock: string;
  brandId: number | null;
  modelId: number | null;
  categories: number[];
  tags: string[];
  allowedPayment: number[];
  resources: {
    rawFile: File;
    kind: "image" | "video";
    role: number;
  }[];
  attributes: {
    configName: string;
    options: { name: string; isDefault: boolean }[];
  }[];
  combinations?: CombinationPayload[];
}

// Fonction unique recevant directement le FormData construit par le composant
export const createProduct = async (formData: FormData) => {
  const response = await apiClient.post("api/products/create", formData, {
    headers: {
      "Content-Type": "multipart/form-data",
    },
  });
  return response.data;
};
