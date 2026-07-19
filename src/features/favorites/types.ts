export interface FavoriteRecord {
  isFavorite: boolean;
  favoritesCount: number;
  updatedAt: string;
}

export type FavoritesState = Record<string, FavoriteRecord>;
