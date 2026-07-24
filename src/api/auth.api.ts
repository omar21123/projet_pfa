// src/api/auth.api.ts
import axiosInstance, { setAuthAccessToken } from "./axiosInstances";
import {
  LoginRequest,
  RegisterRequestClient,
  LaravelAuthResponse,
  ApiMessageResponse,
  User,
} from "../types/users.types";

const AUTH_EMAIL_KEY = "authEmail"; // non sensible, uniquement pour l'affichage UX

export const authApi = {
  /**
   * Connexion d'un utilisateur (Web)
   */
  login: async (data: LoginRequest): Promise<LaravelAuthResponse> => {
    const response = await axiosInstance.post<LaravelAuthResponse>(
      "/api/auth/web/login",
      data
    );
    const payload = response.data;

    // L'access token reste uniquement en mémoire (jamais en localStorage)
    setAuthAccessToken(payload.access_token);
    localStorage.setItem(AUTH_EMAIL_KEY, data.email);

    return payload;
  },

  /**
   * Inscription d'un compte Client (Web)
   */
  registerClient: async (data: RegisterRequestClient): Promise<ApiMessageResponse> => {
    const response = await axiosInstance.post<ApiMessageResponse>(
      "/api/auth/web/customer/register",
      data
    );
    return response.data;
  },

  /**
   * Inscription d'un compte Fournisseur / Partenaire (Web)
   * Reçoit un FormData (obligatoire pour l'envoi de fichier multipart comme l'avatar)
   */
  registerVendor: async (formData: FormData): Promise<ApiMessageResponse> => {
    const response = await axiosInstance.post<ApiMessageResponse>(
      "/api/auth/web/vendor/register",
      formData,
      {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      }
    );
    return response.data;
  },

  /**
   * Connexion via Google (Web) — envoie l'id_token GIS obtenu côté client.
   * Le backend crée le compte s'il n'existe pas, ou le lie/connecte s'il existe déjà.
   */
  loginWithGoogle: async (idToken: string): Promise<LaravelAuthResponse> => {
    const response = await axiosInstance.post<LaravelAuthResponse>(
      "/api/auth/web/google",
      { id_token: idToken }
    );
    const payload = response.data;

    setAuthAccessToken(payload.access_token);

    return payload;
  },

  /**
   * Déconnexion complète (Web) - Révoque la session et nettoie le cookie HttpOnly
   */
  logout: async (): Promise<ApiMessageResponse> => {
    try {
      const response = await axiosInstance.post<ApiMessageResponse>("/api/auth/web/logout");
      return response.data;
    } finally {
      // Nettoyage local peu importe le résultat de la requête réseau
      setAuthAccessToken(null);
      localStorage.removeItem(AUTH_EMAIL_KEY);
    }
  },

  /**
   * Récupération des détails de l'utilisateur connecté
   */
  getCurrentUserProfile: async (): Promise<User> => {
    const response = await axiosInstance.get<User>("/api/auth/me");
    return response.data;
  }
};