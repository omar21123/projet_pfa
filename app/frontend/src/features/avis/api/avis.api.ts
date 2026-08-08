import { apiClient } from "@/api/client";
import type { AvisItem } from "@/features/avis/types";
import { usersApi } from "@/api/users.api";
import { getAuthAccessToken } from "@/api/axiosInstance";
import type { UserProfile } from "@/types/user.types";

type ApiEnvelope<T> = {
  data?: T;
  message?: string;
  success?: boolean;
  errors?: string[];
};

const unwrapAvisList = (payload: unknown): AvisItem[] => {
  if (Array.isArray(payload)) {
    return payload as AvisItem[];
  }

  if (!payload || typeof payload !== "object") {
    return [];
  }

  const envelope = payload as ApiEnvelope<unknown>;
  const firstLevelData = envelope.data;

  if (Array.isArray(firstLevelData)) {
    return firstLevelData as AvisItem[];
  }

  if (firstLevelData && typeof firstLevelData === "object") {
    const nestedData = (firstLevelData as ApiEnvelope<unknown>).data;
    if (Array.isArray(nestedData)) {
      return nestedData as AvisItem[];
    }
  }

  return [];
};

const canEnrichUserProfiles = () =>
  Boolean(
    getAuthAccessToken() ??
    localStorage.getItem("authToken") ??
    localStorage.getItem("accessToken"),
  );

const enrichAvisWithUserProfiles = async (avis: AvisItem[]): Promise<AvisItem[]> => {
  if (!canEnrichUserProfiles()) {
    return avis;
  }

  const userIds = Array.from(
    new Set(
      avis
        .map((avisItem) => avisItem.id_utilisateur)
        .filter((userId): userId is number => Number.isFinite(userId)),
    ),
  );

  const profiles = new Map<number, UserProfile | null>();

  await Promise.all(
    userIds.map(async (userId) => {
      try {
        const profile = await usersApi.getById(userId);
        profiles.set(userId, profile);
      } catch {
        profiles.set(userId, null);
      }
    }),
  );

  return avis.map((avisItem) => ({
    ...avisItem,
    utilisateur:
      avisItem.id_utilisateur !== undefined
        ? (profiles.get(avisItem.id_utilisateur) ?? null)
        : null,
  }));
};

export const avisApi = {
  getByAnnonceId: async (annonceId: number): Promise<AvisItem[]> => {
    const response = await apiClient.get<unknown>(`/api/Avis/${annonceId}`);
    return enrichAvisWithUserProfiles(unwrapAvisList(response.data));
  },

  submit: async (annonceId: number, note: number, commentaire: string): Promise<void> => {
    await apiClient.post("/api/Avis", null, {
      params: {
        id_annonce: annonceId,
        note,
        cmt: commentaire,
      },
    });
  },
};
