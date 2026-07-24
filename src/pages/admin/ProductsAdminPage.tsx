import React, { useState, useEffect } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import { FilterParams, ProductListItem } from "../../types/moderation";
import { moderationApi } from "@/api/moderationApi";
import { ProductsFilterBar } from "../../components/moderation/ProductsFilterBar";
import { ProductsTable } from "../../components/moderation/ProductsTable";
import { Pagination } from "../../components/moderation/Pagination";
import { ActionModal } from "../../components/moderation/ActionModal";

const DEFAULT_FILTERS: FilterParams = {
  search: "",
  status: "any",
  vendor_id: "",
  brand_id: "",
  model_id: "",
  is_active: "any",
  is_blocked: "any",
  date_from: "",
  date_to: "",
  page: 1,
  per_page: 20,
};

export  const ProductsAdminPage: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();

  const [products, setProducts] = useState<ProductListItem[]>([]);
  const [meta, setMeta] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [errorBanner, setErrorBanner] = useState<string | null>(null);

  // Boîtes Modales
  const [modalType, setModalType] = useState<"validate" | "refuse" | "block">("validate");
  const [selectedProduct, setSelectedProduct] = useState<ProductListItem | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Synchronisation de l'URL vers l'état React
  const currentFilters: FilterParams = {
    search: searchParams.get("search") || "",
    status: searchParams.get("status") || "any",
    vendor_id: searchParams.get("vendor_id") || "",
    brand_id: searchParams.get("brand_id") || "",
    model_id: searchParams.get("model_id") || "",
    is_active: searchParams.get("is_active") || "any",
    is_blocked: searchParams.get("is_blocked") || "any",
    date_from: searchParams.get("date_from") || "",
    date_to: searchParams.get("date_to") || "",
    page: parseInt(searchParams.get("page") || "1", 10),
    per_page: parseInt(searchParams.get("per_page") || "20", 10),
  };

 const fetchProductList = async () => {
    setLoading(true);
    setErrorBanner(null);
    try {
      // L'API renvoie directement l'objet contenant { data, meta }
      const response = await moderationApi.getProducts(currentFilters);
      
      // On valide que la structure attendue est bien présente
      if (response && Array.isArray(response.data)) {
        setProducts(response.data);
        setMeta(response.meta);
      } else {
        setErrorBanner("Le format des données renvoyé par le serveur est incorrect.");
      }
    } catch (err: any) {
      console.error("Erreur API Modération:", err);
      setErrorBanner(
        err.response?.data?.message || "Impossible de charger le catalogue de modération."
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProductList();
  }, [searchParams]);

  const updateUrlFilters = (newParams: Partial<FilterParams>) => {
    const updated = { ...currentFilters, ...newParams };
    if (!newParams.page) updated.page = 1; // Réinitialise à la page 1 si un filtre change

    const cleanedParams: Record<string, string> = {};
    Object.entries(updated).forEach(([k, v]) => {
      if (v !== "" && v !== "any" && v !== null) {
        cleanedParams[k] = String(v);
      }
    });
    setSearchParams(cleanedParams);
  };

  const handleOpenActionModal = (type: "validate" | "refuse", product: ProductListItem) => {
    setModalType(type);
    setSelectedProduct(product);
    setIsModalOpen(true);
  };

  const handleExecuteModalAction = async (notes: string) => {
    if (!selectedProduct) return;
    const id = selectedProduct.product_id;

    if (modalType === "validate") {
      await moderationApi.validateProduct(id, notes);
    } else {
      const res = await moderationApi.refuseProduct(id, notes);
      if (res.auto_blocked) {
        alert("Ce produit a dépassé les 3 échecs et a été automatiquement bloqué.");
      }
    }
    fetchProductList(); // Re-fetch strict préconisé
  };

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-slate-800">Espace de Modération des Produits</h1>
        <p className="text-slate-500 text-sm">Gérez et validez les annonces des vendeurs tiers.</p>
      </div>

      {errorBanner && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-xl font-medium flex justify-between items-center">
          <span>{errorBanner}</span>
          <button
            onClick={fetchProductList}
            className="px-3 py-1 bg-red-600 text-white text-xs rounded-lg font-semibold hover:bg-red-700"
          >
            Réessayer
          </button>
        </div>
      )}

      <ProductsFilterBar
        filters={currentFilters}
        onFilterChange={updateUrlFilters}
        onClearFilters={() => setSearchParams({})}
      />

      <ProductsTable
        products={products}
        loading={loading}
        onViewDetails={(id) => navigate(`/admin/products/${id}`)}
        onActionClick={handleOpenActionModal}
      />

      {meta && (
        <Pagination
          currentPage={currentFilters.page}
          lastPage={meta.last_page}
          totalItems={meta.total}
          pageSize={currentFilters.per_page}
          onPageChange={(p) => updateUrlFilters({ page: p })}
        />
      )}

      <ActionModal
        isOpen={isModalOpen}
        type={modalType}
        product={selectedProduct}
        onClose={() => setIsModalOpen(false)}
        onConfirm={handleExecuteModalAction}
      />
    </div>
  );
};
