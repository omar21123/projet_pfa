import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/contexts";
import { avisApi } from "@/features/avis/api/avis.api";

const AVIS_QUERY_KEY = (annonceId: number) => ["avis", annonceId] as const;

export const useAvis = (annonceId: number) => {
  const queryClient = useQueryClient();
  const { isAuthenticated } = useAuth();
  const isValidAnnonceId = Number.isFinite(annonceId);

  const avisQuery = useQuery({
    queryKey: AVIS_QUERY_KEY(annonceId),
    queryFn: () => avisApi.getByAnnonceId(annonceId),
    enabled: isValidAnnonceId,
    refetchOnWindowFocus: false,
    retry: false,
  });

  const mutation = useMutation({
    mutationFn: async ({ note, commentaire }: { note: number; commentaire: string }) => {
      if (!isAuthenticated) {
        throw new Error("Veuillez vous connecter pour publier un avis.");
      }

      if (!isValidAnnonceId) {
        throw new Error("Identifiant d'annonce invalide.");
      }

      await avisApi.submit(annonceId, note, commentaire);
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: AVIS_QUERY_KEY(annonceId) });
    },
  });

  return {
    avis: avisQuery.data ?? [],
    loading: avisQuery.isLoading,
    error: avisQuery.error,
    submitAvis: mutation.mutateAsync,
    isSubmitting: mutation.isPending,
  };
};
