export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  status?: number; // Requis spécifiquement pour le CountryController
  pagination?: {
    total: number;
    page: number;
    perPage: number;
    lastPage: number;
  };
}

export interface Country {
  CountryID: number;
  Name: string;
  [key: string]: any; // Permet de tolérer d'autres colonnes de la table
}

export interface Tag {
  TagID: number;
  Name: string;
  Color: string | null;
  Description: string | null;
  IsActive: boolean | number;
  CreatedAt: string;
  UpdatedAt?: string;
}

export interface Unit {
  UnitID: number;
  Name: string;
  Symbol: string;
  DisplayOrder: number | null;
  IsActive: boolean | number;
  CreatedAt: string;
  UpdatedAt?: string;
}

export interface ProductModel {
  ModelID: number;
  BrandID: number;
  Name: string;
  Code: string | null;
  Description: string | null;
  ReleaseYear: number | null;
  IsActive: boolean | number;
  CreatedAt: string;
  UpdatedAt: string;
}

export interface Brand {
  BrandID: number;
  Name: string;
  Slug: string;
  LogoURL: string | null;
  Website: string | null;
  Description: string | null;
  CountryID: number | null;
  IsActive: boolean | number;
  CreatedAt: string;
  UpdatedAt: string;
  CountryName: string | null;
}

// Filtres d'administration pour vos requêtes de listes
export interface AdminFilters {
  search?: string;
  isActive?: boolean | string;
  brandID?: number;
  sortBy?: string;
  sortDir?: "asc" | "desc";
  page?: number;
  perPage?: number;
}

// Modèle de données : Country
export interface Country {
  CountryID: number;
  Name: string;
  Code: string; // ex: MA, FR
  FlagEmoji?: string;
}