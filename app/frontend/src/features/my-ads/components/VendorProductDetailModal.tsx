import React, { useState, useEffect } from "react";
import { getVendorProductDetail } from "@/api/productVendorApi";
import { ImageWithFallback } from "./ImageWithFallback";
import { VideoPlayer } from "@/components/VideoPlayer";
import { getMediaUrl } from "@/utils/mediaUtils";

interface Props {
  productId: number | null;
  isOpen: boolean;
  onClose: () => void;
}

export const VendorProductDetailModal: React.FC<Props> = ({
  productId,
  isOpen,
  onClose,
}) => {
  const [product, setProduct] = useState<any | null>(null);
  const [loading, setLoading] = useState<boolean>(false);

  useEffect(() => {
    if (isOpen && productId && productId !== ("undefined" as any)) {
      fetchProduct();
    }
  }, [isOpen, productId]);

  const fetchProduct = async () => {
    if (!productId) return;
    setLoading(true);
    try {
      const data = await getVendorProductDetail(productId);
      setProduct(data);
    } catch (err) {
      console.error("Erreur lors de la récupération du produit:", err);
      setProduct(null);
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  const videoUrl = product?.videos?.[0]?.url;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4">
      <div className="bg-white rounded-2xl max-w-xl w-full p-6 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center border-b border-slate-100 pb-3 mb-4">
          <h3 className="text-base font-bold text-slate-800">
            Fiche Produit #{productId}
          </h3>
          <button
            onClick={onClose}
            className="size-7 rounded-full bg-slate-100 text-slate-400 hover:text-slate-700 flex items-center justify-center font-bold"
          >
            ×
          </button>
        </div>

        {loading ? (
          <div className="py-12 text-center text-slate-400 text-xs font-medium animate-pulse">
            Chargement des détails...
          </div>
        ) : product ? (
          <div className="space-y-4 text-xs">
            <div className="flex gap-4 items-center bg-slate-50 p-3 rounded-xl border border-slate-100">
              <div className="size-16 rounded-xl border border-slate-200 overflow-hidden flex-shrink-0 bg-white">
                <ImageWithFallback
                  src={getMediaUrl(product.main_image)}
                  alt={product.product_name || "Produit"}
                />
              </div>
              <div className="flex-1">
                <h4 className="font-bold text-slate-800 text-sm">{product.product_name}</h4>
                <p className="text-slate-400 font-mono text-[11px]">
                  Marque: {product.brand_name || "N/A"}
                </p>
                <p className="text-slate-500 font-mono text-[11px]">
                  Modèle: {product.model_name || "N/A"}
                </p>
              </div>
              <div className="text-right">
                <span className="text-[10px] text-slate-400 block font-bold uppercase">Stock</span>
                <span className="text-sm font-extrabold text-slate-800">
                  {product.stock ?? 0} u.
                </span>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-slate-400 block text-[10px] uppercase font-bold">
                  Code-barres
                </span>
                <span className="font-semibold text-slate-700">
                  {product.barcode || "—"}
                </span>
              </div>
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-slate-400 block text-[10px] uppercase font-bold">Statut</span>
                <span className="font-semibold text-slate-700">{product.status}</span>
              </div>
            </div>

            {videoUrl && (
              <div className="space-y-2">
                <h4 className="font-bold text-slate-700 text-xs">Vidéos de présentation</h4>
                <VideoPlayer src={videoUrl} />
              </div>
            )}
          </div>
        ) : (
          <div className="py-8 text-center text-slate-400 text-xs">
            Impossible de charger le produit.
          </div>
        )}

        <div className="mt-6 text-right">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-slate-800 text-white rounded-xl text-xs font-semibold hover:bg-slate-700"
          >
            Fermer
          </button>
        </div>
      </div>
    </div>
  );
};
