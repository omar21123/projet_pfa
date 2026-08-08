import axios from "axios";
import { useCallback, useEffect, useState } from "react";
import { usersApi } from "@/api/users.api";
import { useUser } from "@/hooks/useUser";
import type { UserProfile } from "@/types/user.types";

interface UseProfileReturn {
  data: UserProfile | null;
  isLoading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
}

const getErrorMessage = (error: unknown): string => {
  if (axios.isAxiosError(error)) {
    const apiMessage = (error.response?.data as { message?: string; errors?: string[] } | undefined)
      ?.message;
    return (
      apiMessage || error.response?.data?.errors?.[0] || error.message || "Une erreur est survenue"
    );
  }

  if (error instanceof Error) {
    return error.message;
  }

  return "Une erreur est survenue";
};

export const useProfile = (): UseProfileReturn => {
  const { user, isLoading: isUserLoading } = useUser();
  const [data, setData] = useState<UserProfile | null>(null);
  const [isFetching, setIsFetching] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchProfile = useCallback(async () => {
    if (!user) {
      setData(null);
      setError("Utilisateur introuvable.");
      return;
    }

    setIsFetching(true);
    setError(null);

    try {
      const profile = await usersApi.getCurrentUserProfile();
      setData(profile);
    } catch (err) {
      const userId = Number(user.id);

      if (Number.isFinite(userId)) {
        try {
          const profile = await usersApi.getById(userId);
          setData(profile);
          return;
        } catch {
          // Keep the original /me error message for clearer diagnostics.
        }
      }

      setData(null);
      setError(getErrorMessage(err));
    } finally {
      setIsFetching(false);
    }
  }, [user]);

  useEffect(() => {
    if (isUserLoading) {
      return;
    }

    void fetchProfile();
  }, [fetchProfile, isUserLoading]);

  return {
    data,
    isLoading: isUserLoading || isFetching,
    error,
    refetch: fetchProfile,
  };
};
