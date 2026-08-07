export interface Favorite {
  productLikeId: number;
  productId: number;
  productName: string;
  productImage: string | null;
  basePrice: number;
  brandName: string | null;
  likedAt: string;
}

export interface AddFavoriteRequest {
  product_id: number;
}

export interface FavoriteCreated {
  productLikeId: number;
}

export interface FavoritesResponse {
  success: boolean;
  message?: string;
  data: Favorite[];
}
export interface FavoriteRecord {
  isFavorite: boolean;
  favoritesCount: number;
  updatedAt: string;
}

// Dictionnaire indexé par productId (converti en string).
export type FavoritesState = Record<string, FavoriteRecord>;