export interface SimilarProduct {
  ProductID: number;
  ProductName: string;
  ProductDesc: string | null;
  BasePrice: number;
  BrandName: string | null;
  BrandID: number | null;
  ModelName: string | null;
  Stock: number;
  TotalOrders: number;
  TotalWishlists: number;
  TotalLikes: number;
  ProductImage?: string | null;
}

export interface SimilarProductsData {
  SimilarProducts: SimilarProduct[];
  SimilarInBrandsOrModels: SimilarProduct[];
  SimilarInCategories: SimilarProduct[];
}

export interface SimilarProductsResponse {
  success: boolean;
  data: SimilarProductsData;
  message?: string;
}
