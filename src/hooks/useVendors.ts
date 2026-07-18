// src/hooks/useVendors.ts
import { useMutation, useQuery, useQueryClient, UseMutationResult } from "@tanstack/react-query";
import axios from "axios";
import { vendorsApi } from "@/api/vendors.api";
import { VendorActionResponse, VendorListFilters } from "@/types/vendor.types";
import { useToast } from "@/hooks/use-toast";

const VENDORS_ROOT_KEY = ["admin", "vendors"] as const;

export const vendorsQueryKey = (filters: VendorListFilters) => [...VENDORS_ROOT_KEY, filters] as const;

/**
 * Liste paginée + filtrée des vendeurs.
 * `placeholderData` garde l'ancienne page affichée pendant le chargement de la suivante
 * (évite le flash de contenu vide lors de la pagination).
 */
export function useVendorsList(filters: VendorListFilters) {
  return useQuery({
    queryKey: vendorsQueryKey(filters),
    queryFn: () => vendorsApi.list(filters),
    placeholderData: (previousData) => previousData,
  });
}

const getErrorMessage = (error: unknown): string => {
  if (axios.isAxiosError(error)) {
    return error.response?.data?.message ?? error.message ?? "Une erreur est survenue.";
  }
  return error instanceof Error ? error.message : "Une erreur est survenue.";
};

/**
 * Factory commune à toutes les actions vendeur : invalide le cache de liste
 * et affiche un toast de succès/erreur cohérent.
 */
function useVendorAction<TVariables>(
  mutationFn: (variables: TVariables) => Promise<VendorActionResponse>,
  fallbackSuccessMessage: string
): UseMutationResult<VendorActionResponse, unknown, TVariables> {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation({
    mutationFn,
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: VENDORS_ROOT_KEY });
      toast({ title: "Succès", description: data.message ?? fallbackSuccessMessage });
    },
    onError: (error) => {
      toast({
        title: "Erreur",
        description: getErrorMessage(error),
        variant: "destructive",
      });
    },
  });
}

export function useVerifyVendorIdentity() {
  return useVendorAction<{ id: number; notes?: string }>(
    ({ id, notes }) => vendorsApi.verifyIdentity(id, notes),
    "Identité du vendeur vérifiée."
  );
}

export function useApproveVendor() {
  return useVendorAction<{ id: number; notes?: string }>(
    ({ id, notes }) => vendorsApi.approve(id, notes),
    "Vendeur approuvé."
  );
}

export function useRejectVendor() {
  return useVendorAction<{ id: number; notes: string }>(
    ({ id, notes }) => vendorsApi.reject(id, notes),
    "Vendeur rejeté."
  );
}

export function useResetVendorToPending() {
  return useVendorAction<{ id: number; notes?: string }>(
    ({ id, notes }) => vendorsApi.resetToPending(id, notes),
    "Vendeur remis en attente."
  );
}
