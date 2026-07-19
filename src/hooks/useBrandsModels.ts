import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { adminService } from "@/api/brand_tag_model_unit";
import { useToast } from "@/hooks/use-toast";
import type { AdminFilters } from "@/types/brand_tag_model_unit";

const BRANDS_KEY = ["admin", "brands"] as const;
const MODELS_KEY = ["admin", "models"] as const;

export function useBrandsModels() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  // --- QUERIES ---
  const useBrandsList = (filters: AdminFilters) => useQuery({
    queryKey: [...BRANDS_KEY, filters],
    queryFn: () => adminService.brands.fetch(filters),
  });

  const useModelsList = (filters: AdminFilters) => useQuery({
    queryKey: [...MODELS_KEY, filters],
    queryFn: () => adminService.models.fetchAdmin(filters),
  });

  // --- MUTATIONS BRANDS ---
  const createBrand = useMutation({
    mutationFn: adminService.brands.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: BRANDS_KEY });
      toast({ title: "Succès", description: "Marque ajoutée avec succès." });
    },
    onError: (err: any) => {
      toast({ title: "Erreur", description: err.response?.data?.message || "Échec de la création.", variant: "destructive" });
    }
  });

  const toggleBrandStatus = useMutation({
    mutationFn: ({ id, active }: { id: number; active: boolean }) => 
      active ? adminService.brands.enable(id) : adminService.brands.disable(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: BRANDS_KEY });
      toast({ title: "Statut mis à jour", description: "Le statut de la marque a été modifié." });
    },
  });

  // --- MUTATIONS MODELS ---
  const createModel = useMutation({
    mutationFn: adminService.models.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: MODELS_KEY });
      toast({ title: "Succès", description: "Le modèle a été créé." });
    },
    onError: (err: any) => {
      toast({ title: "Erreur", description: err.response?.data?.message || "Échec de la création.", variant: "destructive" });
    }
  });

  const updateModel = useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: any }) => adminService.models.update(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: MODELS_KEY });
      toast({ title: "Succès", description: "Le modèle a été mis à jour." });
    },
    onError: (err: any) => {
      toast({ title: "Erreur", description: err.response?.data?.message || "Échec de la modification.", variant: "destructive" });
    }
  });

  const toggleModelStatus = useMutation({
    mutationFn: ({ id, active }: { id: number; active: boolean }) => 
      active ? adminService.models.enable(id) : adminService.models.disable(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: MODELS_KEY });
      toast({ title: "Statut mis à jour", description: "Le statut du modèle a été modifié." });
    },
  });

  return { 
    useBrandsList, 
    useModelsList, 
    createBrand, 
    toggleBrandStatus, 
    createModel, 
    updateModel, 
    toggleModelStatus 
  };
}