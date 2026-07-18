export interface Category {
  CategoryID: number;
  Name: string;
  Slug: string;
  ParentCategoryID: number | null;
  IconURL: string | null;
  IsActive: boolean | number;
  CreatedAt?: string;
  UpdatedAt?: string;
  children_count?: number; // Pratique pour savoir s'il y a des sous-catégories
}

export interface CategoryFilters {
  search?: string;
  isActive?: boolean;
  hasProducts?: boolean;
  isEmpty?: boolean;
  sortBy?: "Name" | "CreatedAt" | "UpdatedAt" | "DisplayOrder";
  sortDir?: "asc" | "desc";
  page?: number;
  perPage?: number;
}

export interface PaginationData {
  total: number;
  page: number;
  perPage: number;
  lastPage: number;
}

export interface PaginatedCategoryResponse {
  success: boolean;
  message?: string;
  data: Category[];
  pagination: PaginationData;
}

export interface SingleCategoryResponse {
  success: boolean;
  message: string;
  data: Category;
}

export interface ActionCategoryResponse {
  success: boolean;
  message: string;
}
// Nouveau type spécifique pour les éléments du Navbar
export interface NavbarCategory {
  CategoryID: number;
  ParentCategoryID: number | null;
  Name: string;
  Slug: string;
  IconURL: string | null;
  DisplayOrder: number;
  Depth: number;
  children?: NavbarCategory[]; // Construit à la volée côté front pour l'affichage
}

export interface NavbarCategoryResponse {
  success: boolean;
  message: string;
  data: NavbarCategory[];
}