import type { AnnonceDto } from "@/types";

export type FilterSortBy = "date_desc" | "date_asc" | "prix_asc" | "prix_desc" | "recent";

export interface FilterState {
  categorie: string | null;
  sousCategorie: string | null;
  ville: string | null;
  etat: string | null;
  prixMin: number | null;
  prixMax: number | null;
  brand: string | null;
  color: string | null;
  size: string | null;
  searchQuery: string | null;
  sortBy: FilterSortBy;
}

export const getDefaultFilterState = (): FilterState => ({
  categorie: null,
  sousCategorie: null,
  ville: null,
  etat: null,
  prixMin: null,
  prixMax: null,
  brand: null,
  color: null,
  size: null,
  searchQuery: null,
  sortBy: "recent",
});

const normalize = (value: string | null | undefined): string => value?.trim().toLowerCase() ?? "";

const hasText = (value: string | null | undefined): boolean => normalize(value).length > 0;

const parseDate = (value: string): number => {
  const time = new Date(value).getTime();
  return Number.isNaN(time) ? 0 : time;
};

export const countActiveFilters = (filters: FilterState): number => {
  let count = 0;

  if (hasText(filters.categorie)) count += 1;
  if (hasText(filters.sousCategorie)) count += 1;
  if (hasText(filters.ville)) count += 1;
  if (hasText(filters.etat)) count += 1;
  if (filters.prixMin !== null) count += 1;
  if (filters.prixMax !== null) count += 1;
  if (hasText(filters.brand)) count += 1;
  if (hasText(filters.color)) count += 1;
  if (hasText(filters.size)) count += 1;
  if (hasText(filters.searchQuery)) count += 1;
  if (filters.sortBy !== "recent") count += 1;

  return count;
};

export const filterAndSortAds = (ads: AnnonceDto[], filters: FilterState): AnnonceDto[] => {
  const hasMin = filters.prixMin !== null;
  const hasMax = filters.prixMax !== null;
  const priceRangeIsValid =
    !hasMin || !hasMax || (filters.prixMin as number) <= (filters.prixMax as number);
  const searchQuery = normalize(filters.searchQuery);
  const categoryQuery = normalize(filters.categorie);
  const subCategoryQuery = normalize(filters.sousCategorie);
  const cityQuery = normalize(filters.ville);
  const etatQuery = normalize(filters.etat);
  const brandQuery = normalize(filters.brand);
  const colorQuery = normalize(filters.color);
  const sizeQuery = normalize(filters.size);

  const filteredAds = ads.filter((ad) => {
    const adCategory = normalize(ad.categorie);
    const adSubCategory = normalize(ad.sousCategorie);

    if (categoryQuery && adCategory !== categoryQuery && adSubCategory !== categoryQuery) {
      return false;
    }

    if (subCategoryQuery && adSubCategory !== subCategoryQuery) {
      return false;
    }

    if (cityQuery && !normalize(ad.ville).includes(cityQuery)) {
      return false;
    }

    if (etatQuery && normalize(ad.etat) !== etatQuery) {
      return false;
    }

    if (priceRangeIsValid) {
      if (hasMin && ad.prix < (filters.prixMin as number)) {
        return false;
      }

      if (hasMax && ad.prix > (filters.prixMax as number)) {
        return false;
      }
    }

    if (brandQuery && !normalize(ad.brand).includes(brandQuery)) {
      return false;
    }

    if (colorQuery && !normalize(ad.color).includes(colorQuery)) {
      return false;
    }

    if (sizeQuery && normalize(ad.size) !== sizeQuery) {
      return false;
    }

    if (searchQuery) {
      const searchableText = `${ad.titre} ${ad.description}`.toLowerCase();
      if (!searchableText.includes(searchQuery)) {
        return false;
      }
    }

    return true;
  });

  return [...filteredAds].sort((left, right) => {
    switch (filters.sortBy) {
      case "date_asc":
        return parseDate(left.datepublication) - parseDate(right.datepublication);
      case "prix_asc":
        return left.prix - right.prix;
      case "prix_desc":
        return right.prix - left.prix;
      case "date_desc":
      case "recent":
      default:
        return parseDate(right.datepublication) - parseDate(left.datepublication);
    }
  });
};
