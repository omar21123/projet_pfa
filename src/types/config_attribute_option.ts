export interface ConfigAttributeOption {
  id: number;
  ProductsConfigAttributeID: number;
  OptionLabel: string;
  OptionValue: string;
  DisplayOrder?: number | null;
  IsDefaultForAttribute?: boolean;
  IsActive?: boolean;
  CreatedAt?: string;
  UpdatedAt?: string;
}

export interface CreateConfigAttributeOptionPayload {
  ProductsConfigAttributeID: number;
  OptionLabel: string;
  OptionValue: string;
  DisplayOrder?: number | null;
  IsDefaultForAttribute?: boolean;
}

export interface UpdateConfigAttributeOptionPayload {
  ProductsConfigAttributeID?: number;
  OptionLabel?: string;
  OptionValue?: string;
  DisplayOrder?: number | null;
  IsDefaultForAttribute?: boolean;
}

export interface OptionPublicFilters {
  productsConfigAttributeID?: number;
  name?: string;
  page?: number;
  perPage?: number;
}

export interface OptionAdminFilters {
  search?: string;
  isActive?: boolean;
  productsConfigAttributeID?: number;
  sortBy?: "OptionLabel" | "CreatedAt" | "UpdatedAt" | "IsActive" | "DisplayOrder";
  sortDir?: "asc" | "desc";
  page?: number;
  perPage?: number;
}

export interface PaginatedApiResponse<T> {
  success: boolean;
  message: string;
  data: T[];
  pagination: {
    total: number;
    page: number;
    perPage: number;
    lastPage: number;
  };
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}