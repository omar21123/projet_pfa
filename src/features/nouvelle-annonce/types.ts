import type { CategoryNode } from "@/hooks/useCategories";

export type ResourceKind = "image" | "video";

export interface ResourceItem {
  id: string;
  kind: ResourceKind;
  role: number; // 1 = Vidéo, 2 = Image
  name: string;
  previewUrl: string;
  rawFile: File;
}

export interface AttributeOption {
  id: string;
  name: string;
  isDefault?: boolean;
}

export interface ProductAttributeGroup {
  id: string;
  configName: string;
  options: AttributeOption[];
}

export interface VariantOptionPair {
  configName: string;
  optionName: string;
}

export interface VariantCombination {
  id: string;
  sku: string;
  price: string;
  stock: string;
  isDefault: boolean;
  image: File | null;
  previewUrl?: string | null;
  options: VariantOptionPair[];
}

export interface FormState {
  name: string;
  barcode: string;
  description: string;
  basePrice: string;
  stock: string;
  brandId: number | null;
  modelId: number | null;

  // A. Médias & Catégories
  resources: ResourceItem[];
  categories: number[];

  // B. Attributs & Variantes (Matrice)
  attributes: ProductAttributeGroup[];
  combinations: VariantCombination[];

  // C. Options de paiement & Tags
  tags: string[];
  allowedPayment: number[];
}

export const initialState: FormState = {
  name: "",
  barcode: "",
  description: "",
  basePrice: "",
  stock: "0",
  brandId: null,
  modelId: null,

  resources: [],
  categories: [],

  attributes: [],
  combinations: [],

  tags: [],
  allowedPayment: [],
};

export const getCatId = (cat: CategoryNode): number | undefined => {
  const id = cat.CategoryID ?? cat.category_id ?? cat.id;
  return id !== undefined && id !== null ? Number(id) : undefined;
};

export const getCatName = (cat: CategoryNode): string =>
  cat.Name ?? cat.name ?? cat.nom ?? "Sans nom";

export const MOCK_PAYMENTS = [
  { id: 1, nom: "Carte bancaire" },
  { id: 2, nom: "Paiement à la livraison" },
  { id: 3, nom: "Virement bancaire" },
];