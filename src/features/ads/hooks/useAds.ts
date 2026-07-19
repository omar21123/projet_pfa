import { useQuery } from "@tanstack/react-query";
import { adsApi } from "@/api/ads.api";

export const useAds = (filters?: {
  categoryId?: number;
  subCategoryId?: number;
  ville?: string | null;
}) => {
  return useQuery({
    queryKey: ["ads", filters ?? {}],
    queryFn: () => adsApi.getAll(filters),
  });
};
