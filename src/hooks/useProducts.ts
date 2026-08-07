import { useMutation, useQueryClient } from "@tanstack/react-query";
import axios from "axios";
import { createProduct, CreateProductPayload } from "@/api/product";

export function useCreateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    // Accept FormData (multipart) for createProduct
    mutationFn: (payload: FormData) => createProduct(payload),
    onSuccess: (response) => {
      // Invalider les requêtes de listes de produits si nécessaire
      queryClient.invalidateQueries({ queryKey: ["products"] });
      return response;
    },
    onError: (error: unknown) => {
      // Retourne le message d'erreur précis renvoyé par Laravel
      if (axios.isAxiosError(error)) {
        const data = error.response?.data;
        if (data && typeof data === "object" && "message" in data) {
          return String(
            (data as Record<string, unknown>).message ??
              "Une erreur est survenue lors de la création.",
          );
        }
        return "Une erreur est survenue lors de la création.";
      }
      return "Une erreur est survenue lors de la création.";
    },
  });
}
