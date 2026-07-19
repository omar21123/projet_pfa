// src/types/user.types.ts

export interface User {
  public_id: string;
  email: string;
  displayName: string;
  role: "CUSTOMER" | "VENDOR" | "ADMIN";
}

export interface LoginRequest {
  email: string;
  password: string;
}

// Inscription Client (Alignée sur CustomerRegisterRequest)
export interface RegisterRequestClient {
  first_name: string;
  last_name: string;
  email: string;
  password: string;
  phone_number?: string;
  birth_date?: string; // Format "YYYY-MM-DD"
  gender?: number | null; // 1 = Homme, 2 = Femme
}

// Inscription Fournisseur (Correction : company_name à la place de store_name)
export interface RegisterRequestVendor {
  company_name: string;
  description?: string;
  first_name: string;
  last_name: string;
  email: string;
  password: string;
  phone_number?: string;
  birth_date?: string; // Format "YYYY-MM-DD"
  gender?: number | null;
  avatar?: File | null;
}

// Réponses d'authentification directes de Laravel
export interface LaravelAuthResponse {
  message: string;
  role: "CUSTOMER" | "VENDOR" | "ADMIN";
  access_token: string;
  unreadNotifications: number;
  displayName: string;
  verify_email: boolean;
  verify_phone: boolean;
  public_id: string;
}

export interface ApiMessageResponse {
  message: string;
}

export interface RefreshTokenResponse {
  message: string;
  access_token: string;
  public_id: string;
}
