import { useParams, useNavigate } from "react-router-dom";
import { useState, useEffect, useCallback } from "react";
import { getVendorProductDetail } from "@/api/productVendorApi";
import { isValidId } from "@/utils/validation";
import { ImageWithFallback } from "@/features/my-ads/components/ImageWithFallback";
import { getMediaUrl } from "@/utils/mediaUtils";
import type { VendorProductDetail } from "@/types/prodcut";

type FetchState = "idle" | "loading" | "success" | "error" | "invalid";

export default function VendorProductDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const productId = Number(id);

  const [product, setProduct] = useState<VendorProductDetail | null>(null);
  const [fetchState, setFetchState] = useState<FetchState>("idle");
  const [errorMessage, setErrorMessage] = useState("");

  const fetchProduct = useCallback(async () => {
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
      if (status === 404) setErrorMessage("Produit introuvable.");
      else setErrorMessage("Impossible de charger les détails du produit.");
      setProduct(null);
      setFetchState("error");
    }
  }, [productId]);

  useEffect(() => {
    fetchProduct();
  }, [fetchProduct]);

  return (
    <div className="p-6 max-w-2xl mx-auto space-y-4">
      <button
        onClick={() => navigate("/my-ads")}
        className="text-xs text-indigo-600 hover:underline font-medium"
      >
        ← Retour à mes annonces
      </button>

      {fetchState === "loading" && (
        <div className="py-12 text-center text-slate-400 text-sm animate-pulse">
          Chargement...
        </div>
      )}

      {(fetchState === "error" || fetchState === "invalid") && (
        <div className="py-12 text-center">
          <p className="text-rose-500 font-semibold text-sm">{errorMessage}</p>
          <button
            onClick={fetchProduct}
            className="mt-3 px-4 py-2 bg-indigo-600 text-white rounded-lg text-xs font-semibold hover:bg-indigo-700"
          >
            Réessayer
          </button>
        </div>
      )}

      {fetchState === "success" && product && (
        <div className="bg-white rounded-2xl border border-slate-200 p-6 space-y-4 shadow-sm">
          <div className="flex gap-4 items-center">
            <div className="size-20 rounded-xl border border-slate-200 overflow-hidden">
              <ImageWithFallback src={getMediaUrl(product.main_image)} alt={product.product_name} />
            </div>
            <div>
              <h1 className="text-lg font-bold text-slate-800">{product.product_name}</h1>
              <p className="text-xs text-slate-500">Marque : {product.brand_name || "N/A"} — Modèle : {product.model_name || "N/A"}</p>
              <p className="text-xs text-slate-400 font-mono">#{product.product_id}</p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 text-sm">
            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
              <span className="text-slate-400 text-[10px] uppercase font-bold block">Stock</span>
              <span className="font-semibold">{product.stock} u.</span>
            </div>
            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
              <span className="text-slate-400 text-[10px] uppercase font-bold block">Statut</span>
              <span className="font-semibold">{product.status}</span>
            </div>
          </div>

          {product.videos && product.videos.length > 0 && (
            <div>
              <h4 className="text-xs font-bold text-slate-700 mb-2">Vidéos</h4>
              <div className="grid grid-cols-2 gap-2">
                {product.videos.map((vid, idx) => (
                  <video
                    key={idx}
                    controls
                    className="w-full rounded-xl border border-slate-200 bg-black max-h-40"
                  >
                    <source src={getMediaUrl(vid.url)} type="video/mp4" />
                  </video>
                ))}
              </div>
            </div>
          )}

          <button
            onClick={() => navigate("/create")}
            className="px-4 py-2 bg-[#375260] text-white rounded-lg text-xs font-semibold hover:bg-[#2c424e]"
          >
            Modifier le produit
          </button>
        </div>
      )}
    </div>
  );
}
