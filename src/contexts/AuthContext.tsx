// src/context/AuthContext.tsx
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import axios from "axios";
import { jwtDecode } from "jwt-decode";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { authApi } from "@/api/auth.api";
import { setAuthAccessToken, silentRefresh } from "@/api/axiosInstances";
import type {
  LaravelAuthResponse,
  LoginRequest,
  RegisterRequestClient,
  ApiMessageResponse,
} from "@/types/users.types";
import { useToast } from "@/hooks/use-toast";

const AUTH_EMAIL_KEY = "authEmail";

interface AccessTokenPayload {
  sub?: string;
  role?: string | string[];
  roles?: string | string[];
  exp?: number;
  email?: string; // Ajouté si présent dans le JWT
  [key: string]: unknown;
}

function extractRolesFromToken(token: string): string[] {
  try {
    const payload = jwtDecode<AccessTokenPayload>(token);
    const raw = payload.role ?? payload.roles;
    if (!raw) return [];
    return Array.isArray(raw) ? raw : [raw];
  } catch {
    return [];
  }
}

interface AuthContextType {
  accessToken: string | null;
  email: string | null;
  roles: string[];
  isAuthenticated: boolean;
  isBootstrapping: boolean;
  hasRole: (role: string) => boolean;
  login: (email: string, password: string) => Promise<LaravelAuthResponse>;
  logout: () => Promise<void>;
  registerClient: (data: RegisterRequestClient) => Promise<void>;
  registerVendor: (formData: FormData) => Promise<void>;
  // 💡 NOUVELLE MÉTHODE : Pour l'authentification Google via l'ID Token
  loginWithGoogle: (idToken: string) => Promise<LaravelAuthResponse>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

const getErrorMessage = (error: unknown): string => {
  if (axios.isAxiosError(error)) {
    const data = error.response?.data;
    if (data?.errors && typeof data.errors === "object") {
      const firstErrorArray = Object.values(data.errors)[0];
      if (Array.isArray(firstErrorArray) && firstErrorArray.length > 0) {
        return firstErrorArray[0];
      }
    }
    return data?.message ?? error.message ?? "Une erreur est survenue";
  }
  return error instanceof Error ? error.message : "Une erreur est survenue";
};

export const AuthProvider = ({ children }: AuthProviderProps) => {
  const [accessToken, setAccessToken] = useState<string | null>(null);
  const [email, setEmail] = useState<string | null>(() => localStorage.getItem(AUTH_EMAIL_KEY));
  const [roles, setRoles] = useState<string[]>([]);
  const [isBootstrapping, setIsBootstrapping] = useState(true);
  const queryClient = useQueryClient();
  const { toast } = useToast();

  const hasRole = useCallback((role: string) => roles.includes(role), [roles]);

  const clearAuthState = useCallback(() => {
    setAccessToken(null);
    setEmail(null);
    setRoles([]);
    setAuthAccessToken(null);
    localStorage.removeItem(AUTH_EMAIL_KEY);
  }, []);

  // 💡 NOUVELLE MUTATION : Envoi de l'ID Token à votre endpoint POST
  const googleLoginMutation = useMutation<LaravelAuthResponse, Error, string>({
    mutationFn: authApi.loginWithGoogle,
    onSuccess: (response) => {
      const token = response.access_token;
      const responseRole = response.role as string | string[] | undefined;
      const resolvedRoles = responseRole
        ? Array.isArray(responseRole) ? responseRole : [responseRole]
        : extractRolesFromToken(token);

      // L'email vient directement de la réponse backend (voir GoogleAuthController).
      // Fallback sur le JWT au cas où, mais ne devrait pas être nécessaire.
      let userEmail = response.email ?? "";
      if (!userEmail) {
        try {
          const decoded = jwtDecode<AccessTokenPayload>(token);
          userEmail = decoded.email ?? "";
        } catch {}
      }

      setAccessToken(token);
      setEmail(userEmail || null);
      setRoles(resolvedRoles);
      setAuthAccessToken(token);
      if (userEmail) {
        localStorage.setItem(AUTH_EMAIL_KEY, userEmail);
      }

      window.dispatchEvent(
        new CustomEvent("auth:login", {
          detail: { token, roles: resolvedRoles, user: null },
        }),
      );

      toast({
        title: "Connexion réussie",
        description: response.message ?? "Bienvenue via votre compte Google.",
      });
    },
    onError: (error) => {
      toast({
        title: "Erreur d'authentification Google",
        description: getErrorMessage(error),
        variant: "destructive",
      });
    },
  });

  const loginWithGoogle = useCallback(
    async (idToken: string): Promise<LaravelAuthResponse> => {
      return await googleLoginMutation.mutateAsync(idToken);
    },
    [googleLoginMutation],
  );

  // Mutation Connexion Classique
  const loginMutation = useMutation<LaravelAuthResponse, Error, LoginRequest>({
    mutationFn: authApi.login,
    onSuccess: (response, variables) => {
      const token = response.access_token;
      const responseRole = response.role as string | string[] | undefined;   
      const resolvedRoles = responseRole
        ? Array.isArray(responseRole) ? responseRole : [responseRole]
        : extractRolesFromToken(token);

      setAccessToken(token);
      setEmail(variables.email);
      setRoles(resolvedRoles);
      setAuthAccessToken(token);
      localStorage.setItem(AUTH_EMAIL_KEY, variables.email);

      window.dispatchEvent(
        new CustomEvent("auth:login", {
          detail: { token, roles: resolvedRoles, user: null },
        }),
      );

      toast({
        title: "Connexion réussie",
        description: response.message ?? "Bienvenue sur votre espace.",
      });
    },
    onError: (error) => {
      toast({
        title: "Erreur de connexion",
        description: getErrorMessage(error),
        variant: "destructive",
      });
    },
  });

  const login = useCallback(
    async (userEmail: string, password: string): Promise<LaravelAuthResponse> => {
      return await loginMutation.mutateAsync({ email: userEmail, password });
    },
    [loginMutation],
  );

  // Mutation Déconnexion
  const logout = useCallback(async () => {
    try {
      await authApi.logout();
    } catch (error) {
      console.error("Erreur lors de la déconnexion côté serveur", error);
    } finally {
      clearAuthState();
      queryClient.clear();
      window.location.assign("/login");
    }
  }, [clearAuthState, queryClient]);

  // Mutation Inscription Client
  const registerClientMutation = useMutation<ApiMessageResponse, Error, RegisterRequestClient>({
    mutationFn: authApi.registerClient,
    onSuccess: (response) => {
      toast({
        title: "Inscription réussie",
        description: response.message ?? "Votre compte client a été créé avec succès.",
      });
    },
    onError: (error) => {
      toast({
        title: "Erreur d'inscription",
        description: getErrorMessage(error),
        variant: "destructive",
      });
    },
  });

  const registerClient = useCallback(
    async (data: RegisterRequestClient): Promise<void> => {
      await registerClientMutation.mutateAsync(data);
    },
    [registerClientMutation],
  );

  // Mutation Inscription Fournisseur
  const registerVendorMutation = useMutation<ApiMessageResponse, Error, FormData>({
    mutationFn: authApi.registerVendor,
    onSuccess: (response) => {
      toast({
        title: "Demande envoyée",
        description: response.message ?? "Votre compte partenaire a été configuré.",
      });
    },
    onError: (error) => {
      toast({
        title: "Erreur d'inscription partenaire",
        description: getErrorMessage(error),
        variant: "destructive",
      });
    },
  });

  const registerVendor = useCallback(
    async (formData: FormData): Promise<void> => {
      await registerVendorMutation.mutateAsync(formData);
    },
    [registerVendorMutation],
  );

  // Bootstrap initial de l'authentification au montage
  useEffect(() => {
    let isMounted = true;

    const bootstrapAuth = async () => {
      const token = await silentRefresh();

      if (!isMounted) return;

      if (token) {
        setAccessToken(token);
        setRoles(extractRolesFromToken(token));
        const storedEmail = localStorage.getItem(AUTH_EMAIL_KEY);
        if (storedEmail) {
          setEmail(storedEmail);
        }
      } else {
        setAccessToken(null);
        setEmail(null);
        setRoles([]);
        localStorage.removeItem(AUTH_EMAIL_KEY);
      }

      setIsBootstrapping(false);
    };

    bootstrapAuth();

    return () => {
      isMounted = false;
    };
  }, []);

  // Écoute de l'événement de déconnexion globale
  useEffect(() => {
    const onUnauthorized = () => {
      clearAuthState();
      
      const privateRoutes = [
        "/admin", "/dashboard", "/create", "/messages", 
        "/favorites", "/profile", "/ads", "/settings", "/my-ads"
      ];
      
      const currentPath = window.location.pathname;
      const isPrivateRoute = privateRoutes.some((route) => currentPath.startsWith(route));

      if (isPrivateRoute) {
        window.location.assign(`/login?redirect=${encodeURIComponent(currentPath)}`);
      }
    };

    window.addEventListener("unauthorized", onUnauthorized);

    return () => {
      window.removeEventListener("unauthorized", onUnauthorized);
    };
  }, [clearAuthState]);

  const value = useMemo(
    () => ({
      accessToken,
      email,
      roles,
      isAuthenticated: Boolean(accessToken),
      isBootstrapping,
      hasRole,
      login,
      logout,
      registerClient,
      registerVendor,
      loginWithGoogle, // 💡 EXPOSITION DE LA MÉTHODE
    }),
    [accessToken, email, roles, isBootstrapping, hasRole, login, logout, registerClient, registerVendor, loginWithGoogle],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};