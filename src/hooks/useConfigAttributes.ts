// src/hooks/useConfigAttributes.ts
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { configAttributeService } from "../api/config_attribute_service"; //[cite: 16]
import type { AttributeFilters, OptionFilters } from "../types/config_attribute";

const ATTRIBUTES_KEY = "products-config-attributes";
const OPTIONS_KEY = "config-attribute-options";

// ----------------------------------------------------
// HOOKS POUR LES ATTRIBUTS
// ----------------------------------------------------

/** Récupération dynamique / recherche des attributs publics (Vendeur) */
export const usePublicAttributes = (filters: AttributeFilters = {}) =>
  useQuery({
    queryKey: [ATTRIBUTES_KEY, "public", filters],
    queryFn: () => configAttributeService.attributes.fetchPublic(filters), //[cite: 16]
    enabled: filters.name ? filters.name.trim().length > 0 : true,
  });

/** Panel d'administration */
export const useAdminAttributes = (filters: AttributeFilters) =>
  useQuery({
    queryKey: [ATTRIBUTES_KEY, "admin", filters],
    queryFn: () => configAttributeService.attributes.fetchAdmin(filters), //[cite: 16]
  });

export const useCreateAttribute = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: configAttributeService.attributes.create, //[cite: 16]
    onSuccess: () => queryClient.invalidateQueries({ queryKey: [ATTRIBUTES_KEY] }),
  });
};

// ----------------------------------------------------
// HOOKS POUR LES OPTIONS
// ----------------------------------------------------

/** Variantes / options d'un attribut donné (ex: Couleur -> Rouge, Bleu) */
export const useOptionsByAttribute = (attributeId: number | null) =>
  useQuery({
    queryKey: [OPTIONS_KEY, "by-attribute", attributeId],
    queryFn: () => configAttributeService.options.fetchByAttributeId(attributeId!), //[cite: 16]
    enabled: !!attributeId, // Ne s'exécute que si un ID est fourni
  });

/** Liste globale côté administration */
export const useAdminOptions = (filters: OptionFilters) =>
  useQuery({
    queryKey: [OPTIONS_KEY, "admin", filters],
    queryFn: () => configAttributeService.options.fetchAdmin(filters), //[cite: 16]
  });

export const useCreateOption = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: configAttributeService.options.create, //[cite: 16]
    onSuccess: () => queryClient.invalidateQueries({ queryKey: [OPTIONS_KEY] }),
  });
};