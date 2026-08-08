import { useQuery } from "@tanstack/react-query";
import { fetchSearchProducts } from "./searchApi";

export const useSearchProducts = (query: string) => {
  const normalizedQuery = query.trim();

  return useQuery({
    queryKey: ["search", "products", normalizedQuery],
    queryFn: () => fetchSearchProducts(normalizedQuery),
    enabled: normalizedQuery.length > 0,
    staleTime: 30_000,
  });
};
