import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { configAttributeOptionService } from "../api/configAttributeOptionService";
import type {
  OptionPublicFilters,
  CreateConfigAttributeOptionPayload,
} from "../types/config_attribute_option";

export const OPTIONS_QUERY_KEY = "config-attribute-options";

/** Hook de recherche d'options */
export function usePublicOptions(filters: OptionPublicFilters = {}) {
  const hasValueToSearch = (filters.name?.trim().length ?? 0) > 0;
  const hasAttributeId = !!filters.productsConfigAttributeID;

  return useQuery({
    queryKey: [OPTIONS_QUERY_KEY, "public", filters],
    queryFn: () => configAttributeOptionService.fetchPublic(filters),
    // Déclenche la requête si on a une valeur saisie OU un ID d'attribut
    enabled: hasValueToSearch || hasAttributeId,
    staleTime: 1000 * 60 * 2,
  });
}

/** Hook de création d'une option */
export function useCreateOption() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CreateConfigAttributeOptionPayload) =>
      configAttributeOptionService.create(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [OPTIONS_QUERY_KEY] });
    },
  });
}