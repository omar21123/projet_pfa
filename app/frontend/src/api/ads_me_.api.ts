import { apiClient } from "@/api/client";
import type { AnnonceDto, AdStatus } from "@/types";

interface AdsEnvelope {
  data: AnnonceDto[];
  message?: string;
}

export const adsMeApi = {
  getMine: async (status?: AdStatus, signal?: AbortSignal): Promise<AnnonceDto[]> => {
    const url = status ? `/api/Annonce/me/statut/${encodeURIComponent(status)}` : "/api/Annonce/me";
    const { data } = await apiClient.get<AdsEnvelope>(url, { signal });
    return data.data;
  },
};
