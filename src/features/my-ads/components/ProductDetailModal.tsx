import React, { useState, useEffect, useCallback } from "react";
import { ImageWithFallback } from "./ImageWithFallback";
import { getVendorProductDetail } from "@/api/productVendorApi";
import { isValidId } from "@/utils/validation";
import { getMediaUrl } from "@/utils/mediaUtils";
import type { VendorProductDetail } from "@/types/prodcut";

interface Props {
  productId: number | null;
  isOpen: boolean;
  onClose: () => void;
}

type FetchState = "idle" | "loading" | "success" | "error" | "invalid";

export const ProductDetailModal: React.FC<Props> = ({
  productId,
  isOpen,
  onClose,
}) => {
  const [product, setProduct] = useState<VendorProductDetail | null>(null);
  const [fetchState, setFetchState] = useState<FetchState>("idle");
  const [errorMessage, setErrorMessage] = useState("");

  const fetchProductDetails = useCallback(async () => {
    if (!isValidId(productId)) {
      setFetchState("invalid");
      setErrorMessage("Identifiant produit invalide.");
      return;
    }

    setFetchState("loading");
    setErrorMessage("");

    try {
      const data = await getVendorProductDetail(productId);
      setProduct(data);
      setFetchState("success");
    } catch (err: unknown) {
      const status = (err as { response?: { status?: number } })?.response?.status;
      if (status === 404) {
        setErrorMessage("Produit introuvable.");
      } else {
        setErrorMessage("Impossible de charger les détails du produit.");
      }
      setProduct(null);
      setFetchState("error");
    }
  }, [productId]);

  useEffect(() => {
    if (isOpen) {
      setProduct(null);
      setFetchState("idle");
      setErrorMessage("");
      fetchProductDetails();
    }
  }, [isOpen, fetchProductDetails]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4">
      <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center border-b border-slate-100 pb-3 mb-4">
          <h3 className="text-base font-bold text-slate-800">
            Détails du Produit
          </h3>
          <button
            onClick={onClose}
            className="size-7 rounded-full bg-slate-100 text-slate-400 hover:text-slate-700 flex items-center justify-center font-bold"
          >
            ✕
          </button>
        </div>

        {fetchState === "loading" && (
          <div className="py-12 text-center text-slate-400 text-xs font-medium animate-pulse">
            Chargement des détails...
          </div>
        )}

        {(fetchState === "error" || fetchState === "invalid") && (
          <div className="py-12 text-center">
            <div className="text-rose-500 font-semibold text-sm mb-1">
              {errorMessage}
            </div>
            <button
              onClick={fetchProductDetails}
              className="mt-2 px-4 py-1.5 bg-indigo-600 text-white rounded-lg text-xs font-semibold hover:bg-indigo-700"
            >
              Réessayer
            </button>
          </div>
        )}

        {fetchState === "success" && product && (
          <div className="space-y-4 text-xs">
            <div className="flex gap-4 items-center bg-slate-50 p-3 rounded-xl border border-slate-100">
              <div className="size-16 rounded-xl border border-slate-200 overflow-hidden flex-shrink-0">
                <ImageWithFallback src={getMediaUrl(product.main_image)} alt={product.product_name} />
              </div>
              <div>
                <h4 className="font-bold text-slate-800 text-sm">{product.product_name}</h4>
                <p className="text-slate-400 font-mono text-[11px]">Marque : {product.brand_name || "N/A"}</p>
                <p className="text-slate-400 font-mono text-[11px]">Modèle : {product.model_name || "N/A"}</p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-slate-400 block text-[10px] uppercase font-bold">Stock</span>
                <span className="font-semibold text-slate-700">{product.stock} u.</span>
              </div>
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-slate-400 block text-[10px] uppercase font-bold">Statut</span>
                <span className="font-semibold text-slate-700">{product.status}</span>
              </div>
            </div>

            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
              <span className="text-slate-400 font-semibold block mb-1">Code-barres</span>
              <p className="text-slate-700 font-mono">{product.barcode || "—"}</p>
            </div>
          </div>
        )}

        <div className="mt-6 text-right">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-slate-800 text-white rounded-xl text-xs font-semibold hover:bg-slate-700 transition-colors"
          >
            Fermer
          </button>
        </div>
      </div>
    </div>
  );
};
