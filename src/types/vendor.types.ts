// src/types/vendor.types.ts

/**
 * ⚠️ Le Swagger fourni ne détaille pas le schéma exact de `data` (juste `{}`).
 * Cette forme est une hypothèse raisonnable basée sur la description des endpoints
 * ("statistiques agrégées : produits, commandes, revenu", vérification identité/
 * entreprise/banque). À ajuster dès que vous avez la vraie réponse JSON du backend.
 */

/**
 * 0 = Pending (en attente)
 * 1 = Approved (approuvé)
 * 2 = Rejected (rejeté)
 * Hypothèse à confirmer avec le backend.
 */
export type VendorVerificationStatus = 0 | 1 | 2;

export const VERIFICATION_STATUS_LABEL: Record<VendorVerificationStatus, string> = {
  0: "En attente",
  1: "Approuvé",
  2: "Rejeté",
};

export interface VendorStats {
  products_count: number;
  orders_count: number;
  revenue: number;
}

export interface VendorProfile {
  id: number; // vendorProfileId — utilisé dans les routes /api/admin/vendors/{id}/...
  user_id: number;
  store_name: string;
  first_name?: string;
  last_name?: string;
  email: string;
  phone_number: string | null;
  avatar_url: string | null;
  description: string | null;

  identity_verified: boolean;
  business_verified: boolean;
  bank_verified: boolean;

  verification_status: VendorVerificationStatus;
  verification_notes: string | null;
  rejection_notes: string | null;

  is_suspended: boolean;
  created_at: string;

  stats: VendorStats;
}

export interface Pagination {
  current_page: number;
  page_size: number;
  total: number;
  total_pages: number;
}

export interface ApiEnvelope<T> {
  success: boolean;
  status: number;
  message: string;
  data: T;
}

export type PaginatedVendorsResponse = ApiEnvelope<{
  items: VendorProfile[];
  pagination: Pagination;
}>;

export type VendorActionResponse = ApiEnvelope<VendorProfile | Record<string, unknown>>;

export interface VendorListFilters {
  search?: string;
  verification_status?: VendorVerificationStatus;
  is_suspended?: 0 | 1;
  page?: number;
  page_size?: number;
}
