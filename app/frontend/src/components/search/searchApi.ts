import axiosInstance, { getAuthAccessToken } from "@/api/axiosInstances";

export interface SuggestionItem {
  text: string;
}

export interface HistoryItem {
  text: string;
  search_count?: number;
  last_searched_at?: string;
}

export interface SearchHistoryData {
  latest: HistoryItem[];
  famous: HistoryItem[];
}

export interface SearchSuggestionsResponse {
  success: boolean;
  data: SuggestionItem[];
  message?: string;
}

export interface SearchHistoryResponse {
  success: boolean;
  data: SearchHistoryData;
  message?: string;
}

export interface SearchCombination {
  text: string;
  score: number;
}

export interface SearchCombinationsPage {
  items: SearchCombination[];
  currentPage: number;
  pageSize: number;
  lastPage?: number;
  total?: number;
}

export interface SearchProductBrand {
  name: string | null;
  logo: string | null;
}

export interface SearchProduct {
  ProductID: number;
  ProductName: string;
  ProductImage: string | null;
  Description: string | null;
  Price: number;
  Brand: SearchProductBrand | null;
  ModelName: string | null;
  TotalWishlist: number;
  TotalLikes: number;
  TotalOrders: number;
  IsLiked: boolean;
  IsWishedList: boolean;
}

export interface SearchProductsPage {
  products: SearchProduct[];
  currentPage: number;
  pageSize: number;
  total: number;
  hasMore: boolean;
}

interface RawCombination {
  text?: unknown;
  combination?: unknown;
  query?: unknown;
  score?: unknown;
}

interface RawPagination {
  current_page?: unknown;
  per_page?: unknown;
  last_page?: unknown;
  total?: unknown;
  data?: RawCombination[];
}

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

const normalizePositiveInteger = (limit: number, fallback: number): number => {
  if (!Number.isFinite(limit)) return fallback;
  return Math.max(1, Math.trunc(limit));
};

const normalizeSuggestionLimit = (limit: number): number => {
  if (!Number.isFinite(limit)) return 10;
  return Math.min(20, Math.max(1, Math.trunc(limit)));
};

const normalizeHistory = (value: unknown): SearchHistoryData => {
  if (!isRecord(value)) return { latest: [], famous: [] };

  const normalizeItems = (items: unknown): HistoryItem[] => {
    if (!Array.isArray(items)) return [];
    return items.filter(
      (item): item is HistoryItem => isRecord(item) && typeof item.text === "string",
    );
  };

  return {
    latest: normalizeItems(value.latest),
    famous: normalizeItems(value.famous),
  };
};

const normalizeSearchProduct = (value: unknown): SearchProduct | null => {
  if (!isRecord(value)) return null;

  const productId = Number(value.ProductID);
  const productName = value.ProductName;
  if (!Number.isFinite(productId) || typeof productName !== "string") return null;

  const rawBrand = isRecord(value.Brand) ? value.Brand : null;
  const brand = rawBrand
    ? {
        name: typeof rawBrand.name === "string" ? rawBrand.name : null,
        logo: typeof rawBrand.logo === "string" ? rawBrand.logo : null,
      }
    : null;

  return {
    ProductID: productId,
    ProductName: productName,
    ProductImage: typeof value.ProductImage === "string" ? value.ProductImage : null,
    Description: typeof value.Description === "string" ? value.Description : null,
    Price: Number(value.Price) || 0,
    Brand: brand,
    ModelName: typeof value.ModelName === "string" ? value.ModelName : null,
    TotalWishlist: Number(value.TotalWishlist) || 0,
    TotalLikes: Number(value.TotalLikes) || 0,
    TotalOrders: Number(value.TotalOrders) || 0,
    IsLiked: Boolean(value.IsLiked),
    IsWishedList: Boolean(value.IsWishedList),
  };
};

/** Suggestions publiques d'autocomplétion. */
export async function fetchSearchSuggestions(
  query: string,
  limit = 10,
  signal?: AbortSignal,
): Promise<SuggestionItem[]> {
  const normalizedQuery = query.trim();
  if (normalizedQuery.length < 2) return [];

  const response = await axiosInstance.get<SearchSuggestionsResponse>(
    "/api/search/suggestions",
    {
      params: {
        q: normalizedQuery,
        limit: normalizeSuggestionLimit(limit),
      },
      signal,
    },
  );

  return response.data.success && Array.isArray(response.data.data)
    ? response.data.data.filter((item) => typeof item?.text === "string")
    : [];
}

/** Historique privé de l'utilisateur connecté et recherches populaires par IP. */
export async function fetchSearchHistory(
  latestLimit = 10,
  famousLimit = 10,
): Promise<SearchHistoryData> {
  // L'API renvoie 404 sans utilisateur authentifié. Évite une requête inutile.
  if (!getAuthAccessToken()) return { latest: [], famous: [] };

  const response = await axiosInstance.get<SearchHistoryResponse>("/api/search/history", {
    params: {
      latest_limit: normalizePositiveInteger(latestLimit, 10),
      famous_limit: normalizePositiveInteger(famousLimit, 10),
    },
  });

  return response.data.success ? normalizeHistory(response.data.data) : { latest: [], famous: [] };
}

/** Génère les combinaisons paginées utilisées avant le matching en base. */
export async function fetchSearchCombinations(
  query: string,
  page = 1,
  pageSize = 20,
): Promise<SearchCombinationsPage> {
  const normalizedQuery = query.trim();
  const normalizedPage = Number.isFinite(page) ? Math.max(1, Math.trunc(page)) : 1;
  const normalizedPageSize = normalizePositiveInteger(pageSize, 20);

  if (!normalizedQuery) {
    return { items: [], currentPage: normalizedPage, pageSize: normalizedPageSize };
  }

  const response = await axiosInstance.get("/api/search", {
    params: {
      q: normalizedQuery,
      page: normalizedPage,
      page_size: normalizedPageSize,
    },
  });

  const payload: unknown = response.data;
  const root = isRecord(payload) ? payload : {};
  const rawData = root.data;
  const pagination = isRecord(rawData) ? (rawData as RawPagination) : undefined;
  const rawItems = Array.isArray(rawData)
    ? rawData
    : pagination?.data ?? (Array.isArray(root.items) ? root.items : []);

  const items = rawItems.reduce<SearchCombination[]>((result, item) => {
    if (!isRecord(item)) return result;
    const rawItem = item as RawCombination;
    const text = rawItem.text ?? rawItem.combination ?? rawItem.query;
    const score = Number(rawItem.score);
    if (typeof text === "string" && Number.isFinite(score)) {
      result.push({ text, score });
    }
    return result;
  }, []);

  return {
    items,
    currentPage: Number(pagination?.current_page) || normalizedPage,
    pageSize: Number(pagination?.per_page) || normalizedPageSize,
    lastPage: Number.isFinite(Number(pagination?.last_page))
      ? Number(pagination?.last_page)
      : undefined,
    total: Number.isFinite(Number(pagination?.total)) ? Number(pagination?.total) : undefined,
  };
}

/** Produits retournés par le matching de recherche utilisé sur la page d'accueil. */
export async function fetchSearchProducts(
  query: string,
  page = 1,
  pageSize = 20,
): Promise<SearchProductsPage> {
  const normalizedQuery = query.trim();
  const normalizedPage = Number.isFinite(page) ? Math.max(1, Math.trunc(page)) : 1;
  const normalizedPageSize = normalizePositiveInteger(pageSize, 20);

  if (!normalizedQuery) {
    return {
      products: [],
      currentPage: normalizedPage,
      pageSize: normalizedPageSize,
      total: 0,
      hasMore: false,
    };
  }

  const response = await axiosInstance.get("/api/search", {
    params: {
      q: normalizedQuery,
      page: normalizedPage,
      page_size: normalizedPageSize,
    },
  });

  const payload: unknown = response.data;
  const root = isRecord(payload) ? payload : {};
  const products = Array.isArray(root.data)
    ? root.data.reduce<SearchProduct[]>((result, item) => {
        const product = normalizeSearchProduct(item);
        if (product) result.push(product);
        return result;
      }, [])
    : [];
  const meta = isRecord(root.meta) ? root.meta : {};

  return {
    products,
    currentPage: Number(meta.page) || normalizedPage,
    pageSize: Number(meta.page_size) || normalizedPageSize,
    total: Number(meta.total) || products.length,
    hasMore: Boolean(meta.has_more),
  };
}
