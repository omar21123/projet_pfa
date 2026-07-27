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

// Inscription Client
export interface RegisterRequestClient {
  first_name: string;
  last_name: string;
  email: string;
  password: string;
  phone_number?: string;
  birth_date?: string; // Format "YYYY-MM-DD"
  gender?: number | null; // 1 = Homme, 2 = Femme
}

// Inscription Fournisseur
export interface RegisterRequestVendor {
  store_name: string;
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

// Réponses d'authentification Laravel
export interface LaravelAuthResponse {
  message?: string;
  role?: "CUSTOMER" | "VENDOR" | "ADMIN" | string | string[] | null;
  access_token: string;
  unreadNotifications?: number;
  displayName?: string;
  verify_email?: boolean;
  verify_phone?: boolean;
  public_id?: string;
  email?: string;
  is_new_user?: boolean;
  requires_onboarding?: boolean;
}

export interface CompleteGoogleProfilePayload {
  role: "CUSTOMER" | "VENDOR";
  first_name?: string;
  last_name?: string;
  phone_number?: string;
  birth_date?: string;
  gender?: number | null;
  store_name?: string;
  description?: string;
}

export interface AuthResponse {
  token: string;
  user?: User;
  message?: string;
}

export interface ApiMessageResponse {
  message: string;
}

export interface RefreshTokenResponse {
  message: string;
  access_token: string;
  public_id: string;
}