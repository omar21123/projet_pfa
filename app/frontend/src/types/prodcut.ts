export interface VendorProductItem {
  product_id: number;
  name: string;
  barcode: string | null;
  base_price: number;
  stock: number;
  status: number;
  status_label: string;
  is_active: boolean;
  is_blocked: boolean;
  brand_name: string | null;
  model_name: string | null;
  main_image: string | null;
  created_at: string;
  updated_at: string;
}

export interface PaginatedMeta {
  total: number;
  page: number;
  page_size: number;
  last_page: number;
}

export interface VendorProductsResponse {
  data: VendorProductItem[];
  meta: PaginatedMeta;
}

export interface VendorProductFilters {
  search?: string;
  status?: number;
  is_active?: boolean;
  is_blocked?: boolean;
  page: number;
  per_page: number;
}

export interface VendorCombinationOption {
  config_name?: string;
  configName?: string;
  option_name?: string;
  optionName?: string;
  option_value?: string;
}

export interface VendorCombination {
  product_id?: number;
  combination_id?: number;
  CombinationID?: number;
  id?: number;
  image_path?: string;
  ImagePath?: string;
  sku?: string;
  SKU?: string;
  price?: number;
  Price?: number;
  stock?: number;
  Stock?: number;
  is_default?: boolean;
  IsDefault?: boolean;
  name?: string;
  options?: VendorCombinationOption[];
}

export interface VendorCombinationDetail {
  ImagePath?: string;
  image_path?: string;
  SKU?: string;
  sku?: string;
  Price?: number;
  price?: number;
  CompareAtPrice?: number;
  compare_at_price?: number;
  Stock?: number;
  stock?: number;
  IsDefault?: boolean;
  is_default?: boolean;
  IsActive?: boolean;
  is_active?: boolean;
  ConfigName?: string;
  OptionName?: string;
  OptionValue?: string;
  options?: VendorCombinationOption[];
}

export interface VendorProductDetail {
  product_id: number;
  product_name: string;
  full_name: string | null;
  brand_name: string | null;
  brand_logo: string | null;
  model_name: string | null;
  status: string;
  barcode: string | null;
  stock: number;
  main_image: string | null;
  created_at: string;
  refuse_attempt: number | null;
  refuse_notes: string | null;
  refused_by: string | null;
  refuse_at: string | null;
  validator_by: string | null;
  validation_notes: string | null;
  validation_date: string | null;
  is_active: boolean;
  deleted_at: string | null;
  is_blocked: boolean;
  blocked_date: string | null;
  blocked_notes: string | null;
  images?: VendorProductDetailImage[];
  videos?: VendorProductDetailVideo[];
}

export interface VendorProductDetailTag {
  name?: string;
}

export interface VendorProductDetailPayment {
  name?: string;
  code?: string;
  icon_url?: string | null;
}

export interface VendorProductDetailCategory {
  name?: string;
  icon_url?: string | null;
  is_primary?: boolean;
}

export interface VendorProductDetailConfig {
  attribute?: string;
  option?: string;
  is_default?: boolean;
}

export interface VendorProductDetailImage {
  url?: string;
  role?: number;
}

export interface VendorProductDetailVideo {
  url?: string;
  role?: number;
}

export interface VendorProductDetailData {
  details: VendorProductDetail;
  tags: VendorProductDetailTag[];
  allowed_payments: VendorProductDetailPayment[];
  categories: VendorProductDetailCategory[];
  configs: VendorProductDetailConfig[];
  images: VendorProductDetailImage[];
  videos: VendorProductDetailVideo[];
}

export interface VendorProductDetailResponse {
  success: boolean;
  data: VendorProductDetailData;
}
