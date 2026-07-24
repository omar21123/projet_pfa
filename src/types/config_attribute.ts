// src/types/config_attribute.ts

// Enveloppe globale de pagination de votre API
export interface PaginationMeta {
  total: number;
  page: number;
  perPage: number;
  lastPage: number;
}

export interface ApiResponseWithPagination<T> {
  success: boolean;
  message: string;
  data: T;
  pagination: PaginationMeta;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

// --- ATTRIBUTS DE CONFIGURATION ---
export interface ProductsConfigAttribute {
  id: number;
  Name: string;
  UnitID: number | null;
  DisplayOrder: number | null;
  IsActive: boolean;
  CreatedAt?: string;
  UpdatedAt?: string;
}

export interface AttributeFilters {
  name?: string;
  search?: string;
  isActive?: boolean;
  unitID?: number;
  sortBy?: 'Name' | 'CreatedAt' | 'UpdatedAt' | 'IsActive' | 'DisplayOrder';
  sortDir?: 'asc' | 'desc';
  page?: number;
  perPage?: number;
}

// --- OPTIONS D'ATTRIBUTS ---
export interface ConfigAttributeOption {
  id: number;
  ProductsConfigAttributeID: number;
  OptionLabel: string;
  OptionValue: string;
  DisplayOrder: number | null;
  IsDefaultForAttribute: boolean;
  IsActive: boolean;
  CreatedAt?: string;
  UpdatedAt?: string;
}

export interface OptionFilters {
  productsConfigAttributeID?: number;
  name?: string;
  search?: string;
  isActive?: boolean;
  sortBy?: 'OptionLabel' | 'CreatedAt' | 'UpdatedAt' | 'IsActive' | 'DisplayOrder';
  sortDir?: 'asc' | 'desc';
  page?: number;
  perPage?: number;
}