export interface ProductAllowedPayment {
  PaymentMethodID: number;
  PaymentMethodName: string;
  code: string;
  IconURL: string | null;
  WithdrawTax: number;
  IsOnline: boolean;
}

export interface ProductOption {
  OptionID: number;
  OptionLabel: string;
  OptionValue: string;
  isDefault: boolean;
}

export interface ProductConfigDetail {
  ConfigID: number;
  ConfigName: string;
  Options: ProductOption[];
}

export interface ConfigSelection {
  ConfigID: number;
  OptionID: number;
}

export interface ProductCombination {
  CombinationID: number;
  SKU: string;
  CombinationPrice: number;
  CompareAtPrice: number | null;
  CombinationStock: number;
  CombinationImage: string | null;
  IsDefault: boolean;
  Configs: ConfigSelection | ConfigSelection[];
}

export interface ProductCategoryInfo {
  CategoryName: string;
  IsPrimary: boolean;
}

export interface ProductVendorInfo {
  id?: number;
  name?: string;
  prenom?: string;
  nom?: string;
  email?: string;
  telephone?: string;
  role?: string;
  isVerified?: boolean;
  estActif?: boolean;
  dateInscription?: string;
  avatar?: string;
}

export interface ProductInfoData {
  ProductID: string | number;
  ProductName: string;
  ProductDescription: string;
  BasePrice: number;
  BrandName?: string | null;
  BrandID?: string | number | null;
  ModelName?: string | null;
  Stock: number;
  TotalSales?: number;
  TotalLiked?: number;
  TotalWishlists?: number;
  ProductCategories?: ProductCategoryInfo[];
  ProductAllowedPayements?: ProductAllowedPayment[];
  ProductDetails?: ProductConfigDetail[];
  DefaultProductImage?: string | { url?: string; path?: string } | null;
  ProductOptionsCombiniason?: ProductCombination[];
  ProductCity?: string;
  PublishedAt?: string;
  ProductVendor?: ProductVendorInfo;
}

export interface ProductInfoResponse {
  success: boolean;
  data: ProductInfoData;
}

export interface ProductInfoRequest {
  ProductID: number;
  FromSearch?: boolean;
  SearchTerm?: string;
}