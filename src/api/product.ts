import { apiClient } from "./client";

export interface CreateProductPayload {
  name: string;
  barcode: string;
  description: string;
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
}

export const createProduct = async (payload: CreateProductPayload) => {
  const formData = new FormData();

  // 1. Données primitives (Requis au format PascalCase selon le controlleur)
  formData.append("Name", payload.name);
  formData.append("Barcode", payload.barcode);
  formData.append("BasePrice", payload.basePrice);
  formData.append("Stock", payload.stock);

  if (payload.description) formData.append("Description", payload.description);
  if (payload.brandId) formData.append("BrandID", String(payload.brandId));
  if (payload.modelId) formData.append("ModelID", String(payload.modelId));

  // 2. Tableaux simples
  payload.categories.forEach((id, index) => {
    formData.append(`Categories[${index}]`, String(id));
  });

  payload.allowedPayment.forEach((id, index) => {
    formData.append(`AllowedPayment[${index}]`, String(id));
  });

  payload.tags.forEach((tag, index) => {
    formData.append(`Tags[${index}]`, tag);
  });

  // 3. Fichiers et Métadonnées (Structure imbriquée lue par le contrôleur)
  payload.resources.forEach((res, index) => {
    formData.append(`Ressource[${index}][type]`, res.kind);
    formData.append(`Ressource[${index}][Role]`, String(res.role));
    formData.append(`Ressource[${index}][file]`, res.rawFile); // Fichier binaire
  });

  // 4. Attributs de configuration complexes (Conforme au CreateProductRequest de Laravel)
  payload.attributes.forEach((attr, attrIdx) => {
    formData.append(`Attribute[${attrIdx}][ConfigName]`, attr.configName);

    attr.options.forEach((opt, optIdx) => {
      formData.append(`Attribute[${attrIdx}][ConfigOptions][${optIdx}][Name]`, opt.name);
      formData.append(
        `Attribute[${attrIdx}][ConfigOptions][${optIdx}][IsDefault]`,
        opt.isDefault ? "1" : "0",
      );
    });
  });

  const { data } = await apiClient.post("/api/products/create", formData, {
    headers: {
      "Content-Type": "multipart/form-data",
    },
  });
  return data;
};
