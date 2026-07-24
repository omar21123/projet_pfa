import { createContext, useCallback, useEffect, useState, ReactNode } from "react";
import { authApi } from "@/api/auth.api";
import { silentRefresh, setAuthAccessToken, getAuthAccessToken } from "@/api/axiosInstances";
import { STORAGE_KEYS } from "@/config/constants";
import type { AuthResponse, User } from "@/types/users.types";

interface UserContextType {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  login: (authResponse: AuthResponse) => void;
  logout: () => Promise<void>;
  updateUser: (name: string) => void;
}

export type { User, UserContextType };

const UserContext = createContext<UserContextType | undefined>(undefined);

export { UserContext };

// Utilitaire pour lire l'utilisateur en cache local (affichage instantané UX)
const readStoredUser = (): User | null => {
  const storedUser = localStorage.getItem(STORAGE_KEYS.USER);
  if (!storedUser) return null;
  try {
    return JSON.parse(storedUser) as User;
  } catch {
    localStorage.removeItem(STORAGE_KEYS.USER);
    return null;
  }
};

export const UserProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(() => readStoredUser());
  const [token, setToken] = useState<string | null>(() => getAuthAccessToken());
  const [isLoading, setIsLoading] = useState(true);

  // 🎯 1. Connexion : Met à jour le State, Axios et le cache local de l'utilisateur
  const login = useCallback((authResponse: AuthResponse) => {
    const nextToken = authResponse.access_token || authResponse.token || null;
    const nextUser = authResponse.user ?? null;

    if (nextToken) {
      setAuthAccessToken(nextToken);
      setToken(nextToken);
    }

    if (nextUser) {
      setUser(nextUser);
      localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(nextUser));
    }
  }, []);

  // 🎯 2. Déconnexion : Nettoie la session backend, Axios et le stockage local
  const logout = useCallback(async () => {
    try {
      await authApi.logout();
    } catch (err) {
      console.error("Erreur lors de la déconnexion :", err);
    } finally {
      setAuthAccessToken(null);
      setToken(null);
      setUser(null);
      localStorage.removeItem(STORAGE_KEYS.USER);
      // Ne pas conserver de token dans localStorage
      localStorage.removeItem(STORAGE_KEYS.TOKEN);
    }
  }, []);

  const updateUser = useCallback(
    (name: string) => {
      if (user) {
        const updatedUser = { ...user, name };
        setUser(updatedUser);
        localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(updatedUser));
      }
    },
    [user],
  );

  // 🎯 3. SILENT REFRESH AU DÉMARRAGE (F5)
  useEffect(() => {
    const initAuth = async () => {
      try {
        // Tente de récupérer un access token en mémoire via le cookie HttpOnly
        const newAccessToken = await silentRefresh();

        if (newAccessToken) {
          setToken(newAccessToken);
          // Récupère les données fraîches du profil utilisateur
          const profile = await authApi.getCurrentUserProfile();
          setUser(profile);
          localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(profile));
        } else {
          // Si pas de session valide, réinitialise l'état
          setUser(null);
          setToken(null);
          localStorage.removeItem(STORAGE_KEYS.USER);
        }
      } catch (error) {
        console.error("Échec de la réhydratation de session :", error);
        setUser(null);
        setToken(null);
        localStorage.removeItem(STORAGE_KEYS.USER);
      } finally {
        setIsLoading(false);
      }
    };

    initAuth();
  }, []);

  // 🎯 4. Écouteur pour la déconnexion forcée (ex: 401 sur Refresh Token)
  useEffect(() => {
    const handleUnauthorized = () => {
      setAuthAccessToken(null);
      setToken(null);
      setUser(null);
      localStorage.removeItem(STORAGE_KEYS.USER);
      localStorage.removeItem(STORAGE_KEYS.TOKEN);
    };

    window.addEventListener("unauthorized", handleUnauthorized);
    return () => {
      window.removeEventListener("unauthorized", handleUnauthorized);
    };
  }, []);

  // 🎯 5. Écouteur pour l'événement personnalisé auth:login
  useEffect(() => {
    const handleAuthLogin = (e: Event) => {
      try {
        const detail = (e as CustomEvent)?.detail ?? {};
        const nextToken = detail.access_token ?? detail.token ?? detail.accessToken ?? null;
        const nextUser = detail.user ?? undefined;

        if (!nextToken) return;
        login({ access_token: nextToken, user: nextUser } as AuthResponse);
      } catch {
        // Ignorer les événements malformés
      }
    };

    window.addEventListener("auth:login", handleAuthLogin as EventListener);
    return () => {
      window.removeEventListener("auth:login", handleAuthLogin as EventListener);
    };
  }, [login]);

  const value = {
    user,
    token,
    isLoading,
    login,
    logout,
    updateUser,
  };

  return <UserContext.Provider value={value}>{children}</UserContext.Provider>;
};