import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useVendorProducts } from "@/hooks/useVendorProducts"; // adaptez le chemin d'import selon votre projet
import type { VendorProductItem, VendorCombination } from "@/types/prodcut";
import { MyAdsFilterBar } from "@/features/my-ads/components/MyAdsFilterBar";
import { MyAdsTable } from "@/features/my-ads/components/MyAdsTable";
import { MyAdsPagination } from "@/features/my-ads/components/MyAdsPagination";
import { VendorCombinationsModal } from "@/features/my-ads/components/VendorCombinationsModal";
import { VendorPromoModal } from "@/features/my-ads/components/VendorPromoModal";
import { VendorProductDetailModal } from "@/features/my-ads/components/VendorProductDetailModal";

export const MyAdsPage: React.FC = () => {
  const navigate = useNavigate();
  const {
    products,
    meta,
    loading,
    error,
    filters,
    updateFilters,
    changePage,
    refetch,
  } = useVendorProducts(10);

  const [comboModalState, setComboModalState] = useState<{
    isOpen: boolean;
    productId: number | null;
    productName: string;
  }>({
    isOpen: false,
    productId: null,
    productName: "",
  });

  const [promoModalState, setPromoModalState] = useState<{
    isOpen: boolean;
    product: VendorProductItem | VendorCombination | null;
  }>({
    isOpen: false,
    product: null,
  });

  const [detailModalState, setDetailModalState] = useState<{
    isOpen: boolean;
    productId: number | null;
  }>({
    isOpen: false,
    productId: null,
  });

  const handleOpenCombinations = (productId: number, productName: string) => {
    setComboModalState({
      isOpen: true,
      productId,
      productName,
    });
  };

  const handleOpenPromo = (product: VendorProductItem | VendorCombination) => {
    setPromoModalState({
      isOpen: true,
      product,
    });
  };

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Top Banner */}
      <div className="flex flex-wrap justify-between items-center gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-800 tracking-tight">
            Mes Annonces Vendeur
          </h1>
          <p className="text-slate-500 text-xs mt-1">
            Gérez votre catalogue de produits, vos déclinaisons, et vos réductions.
          </p>
        </div>
        <button
          onClick={() => navigate("/create")}
          className="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold shadow-md shadow-indigo-100 transition-all flex items-center gap-2"
        >
          <span>+</span> Nouvelle annonce
        </button>
      </div>

      {/* Erreur */}
      {error && (
        <div className="p-4 bg-rose-50 border border-rose-200 text-rose-700 rounded-xl text-xs font-semibold flex justify-between items-center">
          <span>{error}</span>
          <button
            onClick={refetch}
            className="px-3 py-1 bg-rose-600 text-white text-xs rounded-lg font-bold hover:bg-rose-700"
          >
            Réessayer
          </button>
        </div>
      )}

      {/* Filtres */}
      <MyAdsFilterBar filters={filters} onFilterChange={updateFilters} />

      {/* Table Produit */}
      <MyAdsTable
        products={products}
        loading={loading}
        onViewDetails={(id) => setDetailModalState({ isOpen: true, productId: id })}
        onOpenCombinations={handleOpenCombinations}
        onOpenPromo={handleOpenPromo}
              onEdit={(id) => navigate(`/products/${id}`)}
      />

      {/* Pagination */}
      <MyAdsPagination meta={meta} onPageChange={changePage} />

      {/* Modale Combinaisons */}
      <VendorCombinationsModal
        isOpen={comboModalState.isOpen}
        productId={comboModalState.productId}
        productName={comboModalState.productName}
        onClose={() => setComboModalState({ isOpen: false, productId: null, productName: "" })}
        onOpenPromo={(combo) => handleOpenPromo(combo)}
      />

      {/* Modale Promotions */}
      <VendorPromoModal
        isOpen={promoModalState.isOpen}
        product={promoModalState.product}
        onClose={() => setPromoModalState({ isOpen: false, product: null })}
        onSuccess={refetch}
      />

      {/* Modale Détails Produit */}
      <VendorProductDetailModal
        isOpen={detailModalState.isOpen}
        productId={detailModalState.productId}
        onClose={() => setDetailModalState({ isOpen: false, productId: null })}
      />
    </div>
  );
};

export default MyAdsPage;