import { useCallback, useMemo, useState } from "react";
import type { AnnonceDto } from "@/types";
import {
  countActiveFilters,
  filterAndSortAds,
  getDefaultFilterState,
  type FilterState,
} from "@/utils/filterAds";

export const useAdsFilter = (ads: AnnonceDto[]) => {
  const [filters, setFilters] = useState<FilterState>(() => getDefaultFilterState());

  const setFilter = useCallback(<K extends keyof FilterState>(key: K, value: FilterState[K]) => {
    setFilters((current) => ({ ...current, [key]: value }));
  }, []);

  const resetFilters = useCallback(() => {
    setFilters(getDefaultFilterState());
  }, []);

  const filteredAds = useMemo(() => filterAndSortAds(ads, filters), [ads, filters]);
  const activeFilterCount = useMemo(() => countActiveFilters(filters), [filters]);

  return {
    filters,
    setFilter,
    resetFilters,
    filteredAds,
    activeFilterCount,
  };
};
