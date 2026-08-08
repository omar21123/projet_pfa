// L'API renvoie directement data et meta à la racine
export interface ApiResponse<T> {
  data: T;
  meta: {
    total: number;
    page: number;
    page_size: number;
    last_page: number;
  };
}

export type ProductStatusLabel = 'Brouillon' | 'Validé' | 'Refusé' | 'Bloqué';

export interface ProductListItem {
  product_id: number;
  product_name: string;
  full_name: string;
  brand_name: string | null;
  brand_logo: string | null;
  model_name: string | null;
  status: ProductStatusLabel | string;
  created_at: string;
  refuse_attempt: number;
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
}

export interface RefuseResponse {
  success: boolean;
  message: string;
  auto_blocked: boolean;
}

export interface PaymentMethod {
  name: string;
  code: string;
  icon_url: string | null;
}

export interface CategoryItem {
  name: string;
  icon_url: string | null;
  is_primary: boolean;
}

export interface ConfigItem {
  attribute: string;
  option: string;
  is_default: boolean;
}

export interface ProductDetails extends ProductListItem {
  barcode: string;
  stock: number;
  tags: string[];
  allowed_payments: PaymentMethod[];
  categories: CategoryItem[];
  configs: ConfigItem[];
  main_image?: string | null;
  image_path?: string | null;
  video_path?: string | null;
  video?: string | null;
  videos?: any[] | null;
  images?: any[] | null;
}

export interface FilterParams {
  search: string;
  status: string;
  vendor_id: string;
  brand_id: string;
  model_id: string;
  is_active: string; // 'any' | 'true' | 'false'
  is_blocked: string; // 'any' | 'true' | 'false'
  date_from: string;
  date_to: string;
  page: number;
  per_page: number;
}