import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { adminService } from "@/api/brand_tag_model_unit";
import { useToast } from "@/hooks/use-toast";
import type { BaseListFilters } from "@/types/brand_tag_model_unit";

const TAGS_KEY = ["admin", "tags"] as const;
const UNITS_KEY = ["admin", "units"] as const;

export function useTagsUnits() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  // --- QUERIES (Lecture) ---
  const useTagsList = (filters: BaseListFilters) => useQuery({
    queryKey: [...TAGS_KEY, filters],
    queryFn: () => adminService.tags.fetch(filters),
  });

  const useUnitsList = (filters: BaseListFilters) => useQuery({
    queryKey: [...UNITS_KEY, filters],
    queryFn: () => adminService.units.fetch(filters),
  });

  // --- MUTATIONS TAGS (Écriture) ---
  const createTag = useMutation({
    mutationFn: adminService.tags.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: TAGS_KEY });
      toast({ title: "Succès", description: "Le tag a été créé avec succès." });
    },
  });

  const disableTag = useMutation({
    mutationFn: adminService.tags.disable,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: TAGS_KEY });
      toast({ title: "Tag désactivé", description: "Le tag n'est plus actif." });
    },
  });

  // --- MUTATIONS UNITÉS (Écriture) ---
  const createUnit = useMutation({
    mutationFn: adminService.units.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: UNITS_KEY });
      toast({ title: "Succès", description: "L'unité a été ajoutée." });
    },
  });

  const updateUnit = useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: any }) => adminService.units.update(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: UNITS_KEY });
      toast({ title: "Succès", description: "L'unité a été mise à jour." });
    },
  });

  const toggleUnitStatus = useMutation({
    mutationFn: ({ id, active }: { id: number; active: boolean }) => 
      active ? adminService.units.enable(id) : adminService.units.disable(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: UNITS_KEY });
      toast({ title: "Statut mis à jour", description: "L'état de l'unité a changé." });
    },
  });

  return { useTagsList, useUnitsList, createTag, disableTag, createUnit, updateUnit, toggleUnitStatus };
}