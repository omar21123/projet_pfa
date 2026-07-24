import { useMutation, useQueryClient } from "@tanstack/react-query";
import { createProduct, CreateProductPayload } from "@/api/product";

export function useCreateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CreateProductPayload) => createProduct(payload),
    onSuccess: (response) => {
      // Invalider les requêtes de listes de produits si nécessaire
      queryClient.invalidateQueries({ queryKey: ["products"] });
      return response;
    },
    onError: (error: any) => {
      // Retourne le message d'erreur précis renvoyé par Laravel
      const serverMessage = error?.response?.data?.message;
      return serverMessage || "Une erreur est survenue lors de la création.";
    },
  });
}
