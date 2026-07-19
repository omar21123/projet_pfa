import { useQuery } from "@tanstack/react-query";
import { adsApi } from "@/api/ads.api";
import { useAuth } from "@/contexts";

export const useFavoriteAds = () => {
  const { isAuthenticated } = useAuth();

  return useQuery({
    queryKey: ["ads", "favorites"],
    queryFn: adsApi.getFavorites,
    enabled: isAuthenticated,
    staleTime: 1000 * 60 * 5, // 5 minutes
    gcTime: 1000 * 60 * 10, // 10 minutes
  });
};
