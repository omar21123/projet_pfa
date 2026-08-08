import { useQuery } from "@tanstack/react-query";
import { favoritesApi } from "@/features/favorites/api/favorites.api";
import type { Favorite } from "@/features/favorites/types";

const FAVORITE_ADS_QUERY_KEY = ["favorites", "list"] as const;

export const useFavoriteAds = () => {
  return useQuery<Favorite[]>({
    queryKey: FAVORITE_ADS_QUERY_KEY,
    queryFn: async () => {
      const response = await favoritesApi.list();
      return response.data;
    },
  });
};

export { FAVORITE_ADS_QUERY_KEY };