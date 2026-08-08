// src/api/vendors.api.ts
import axiosInstance from "./axiosInstances";
import {
  PaginatedVendorsResponse,
  VendorActionResponse,
  VendorListFilters,
} from "../types/vendor.types";

const BASE = "/api/admin/vendors";

export const vendorsApi = {
  /**
   * GET /api/admin/vendors
   * Liste paginée des vendeurs avec filtres de recherche/statut.
   */
  list: async (filters: VendorListFilters = {}): Promise<PaginatedVendorsResponse> => {
    const response = await axiosInstance.get<PaginatedVendorsResponse>(BASE, {
      params: {
        search: filters.search || undefined,
        verification_status: filters.verification_status ?? undefined,
        is_suspended: filters.is_suspended ?? undefined,
        page: filters.page ?? 1,
        page_size: filters.page_size ?? 20,
      },
    });
    return response.data;
  },

  /**
   * POST /api/admin/vendors/{vendorProfileId}/verify-identity
   */
  verifyIdentity: async (
    vendorProfileId: number,
    verification_notes?: string
  ): Promise<VendorActionResponse> => {
    const response = await axiosInstance.post<VendorActionResponse>(
      `${BASE}/${vendorProfileId}/verify-identity`,
      { verification_notes }
    );
    return response.data;
  },

  /**
   * POST /api/admin/vendors/{vendorProfileId}/approve
   * Échoue en 422 si identité/entreprise/banque ne sont pas toutes vérifiées.
   */
  approve: async (
    vendorProfileId: number,
    verification_notes?: string
  ): Promise<VendorActionResponse> => {
    const response = await axiosInstance.post<VendorActionResponse>(
      `${BASE}/${vendorProfileId}/approve`,
      { verification_notes }
    );
    return response.data;
  },

  /**
   * POST /api/admin/vendors/{vendorProfileId}/reject
   */
  reject: async (
    vendorProfileId: number,
    rejection_notes: string
  ): Promise<VendorActionResponse> => {
    const response = await axiosInstance.post<VendorActionResponse>(
      `${BASE}/${vendorProfileId}/reject`,
      { rejection_notes }
    );
    return response.data;
  },

  /**
   * POST /api/admin/vendors/{vendorProfileId}/reset-to-pending
   */
  resetToPending: async (
    vendorProfileId: number,
    notes?: string
  ): Promise<VendorActionResponse> => {
    const response = await axiosInstance.post<VendorActionResponse>(
      `${BASE}/${vendorProfileId}/reset-to-pending`,
      { notes }
    );
    return response.data;
  },
};
