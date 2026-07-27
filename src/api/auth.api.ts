import axiosInstance, { setAuthAccessToken } from "./axiosInstances";
import {
  LoginRequest,
  RegisterRequestClient,
  LaravelAuthResponse,
  ApiMessageResponse,
  User,
  CompleteGoogleProfilePayload,
} from "../types/users.types";

const AUTH_EMAIL_KEY = "authEmail"; // non sensible, uniquement pour l'affichage UX

export type GoogleLoginPayload =
  | string
  | {
      id_token: string;
      role?: "CUSTOMER" | "VENDOR";
      store_name?: string;
      description?: string;
      phone_number?: string;
      birth_date?: string;
      gender?: number;
    };

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
   * Inscription d'un compte Fournisseur / Partenaire (Web standard)
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
   *
   * 🟢 FIX : accepte désormais soit une simple chaîne (id_token seul, cas
   * CUSTOMER standard), soit un objet complet incluant role/store_name/etc.
   * Avant ce fix, la signature n'acceptait qu'une string : tout objet passé
   * ici (ex: { id_token, role: "VENDOR", store_name, description }) était
   * silencieusement ignoré, donc le rôle et le nom de boutique n'atteignaient
   * jamais le backend lors de l'inscription vendeur via Google.
   */
  loginWithGoogle: async (payload: GoogleLoginPayload): Promise<LaravelAuthResponse> => {
    const body = typeof payload === "string" ? { id_token: payload } : payload;

    const response = await axiosInstance.post<LaravelAuthResponse>(
      "/api/auth/web/google",
      body
    );
    const responseData = response.data;

    setAuthAccessToken(responseData.access_token);

    return responseData;
  },

  /**
   * Finalisation du profil Google (Onboarding / Choix du rôle VENDEDOR)
   * Envoie le rôle choisi (CUSTOMER/VENDOR) ainsi que les infos optionnelles de la boutique.
   */
  completeGoogleProfile: async (
    data: CompleteGoogleProfilePayload
  ): Promise<LaravelAuthResponse> => {
    const response = await axiosInstance.post<LaravelAuthResponse>(
      "/api/auth/google/complete-profile",
      data
    );
    const payload = response.data;

    // Met à jour l'Access Token débloqué avec le rôle VENDOR définitif
    if (payload.access_token) {
      setAuthAccessToken(payload.access_token);
    }

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
  },
};