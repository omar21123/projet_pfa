import { useState, useEffect, useCallback } from 'react';
import { getVendorProducts } from '../api/productVendorApi';
import { VendorProductFilters, VendorProductItem, PaginatedMeta } from '../types/prodcut';

export const useVendorProducts = (initialPerPage = 10) => {
  const [products, setProducts] = useState<VendorProductItem[]>([]);
  const [meta, setMeta] = useState<PaginatedMeta>({
    total: 0,
    page: 1,
    page_size: initialPerPage,
    last_page: 1,
  });
  
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const [filters, setFilters] = useState<VendorProductFilters>({
    search: '',
    status: undefined,
    is_active: undefined,
    is_blocked: undefined,
    page: 1,
    per_page: initialPerPage,
  });

  const fetchProducts = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await getVendorProducts(filters);
      setProducts(response.data);
      setMeta(response.meta);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Erreur lors du chargement de vos annonces.');
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  const updateFilters = (newFilters: Partial<VendorProductFilters>) => {
    setFilters((prev) => ({
      ...prev,
      ...newFilters,
      page: newFilters.page ?? 1, // Réinitialise à la page 1 si un filtre change (sauf si la page est spécifiée)
    }));
  };

  const changePage = (page: number) => {
    setFilters((prev) => ({ ...prev, page }));
  };

  return {
    products,
    meta,
    loading,
    error,
    filters,
    updateFilters,
    changePage,
    refetch: fetchProducts,
  };
};