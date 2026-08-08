// src/features/nouvelle-annonce/types.ts
import type { CategoryNode } from "@/hooks/useCategories";

export type ResourceKind = "image" | "video";

export type ResourceItem = {
  id: string;
  kind: ResourceKind;
  role: number;
  name: string;
  previewUrl: string;
  rawFile: File;
};

// Structure alignée sur les procédures stockées (Get-or-Create à la volée)
export type ChosenAttribute = {
  id: string; // ID local pour la clé React
  configName: string; // ex: "Color"
  optionName: string; // ex: "Red"
};

export type FormState = {
  name: string;
  barcode: string;
  description: string;
  basePrice: string;
  stock: string;
  brandId: number | null;
  modelId: number | null;
  resources: ResourceItem[];
  categories: number[];
  attributes: ChosenAttribute[];
  tags: string[]; // tableau de chaînes libres — plusieurs tags possibles, sans limite
  allowedPayment: number[];
};

export const initialState: FormState = {
  name: "",
  barcode: "",
  description: "",
  basePrice: "",
  stock: "",
  brandId: null,
  modelId: null,
  resources: [],
  categories: [],
  attributes: [],
  tags: [],
  allowedPayment: [],
};

export const getCatId = (cat: CategoryNode): number | undefined =>
  cat.CategoryID ?? cat.category_id ?? cat.id;

export const getCatName = (cat: CategoryNode): string =>
  cat.Name ?? cat.name ?? cat.nom ?? "";

export const MOCK_PAYMENTS = [
  { id: 1, nom: "Carte bancaire" },
  { id: 2, nom: "Paiement à la livraison" },
  { id: 3, nom: "Virement bancaire" },
];
